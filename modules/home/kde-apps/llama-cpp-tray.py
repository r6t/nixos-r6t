#!/usr/bin/env python3
# pylint: disable=invalid-name,missing-function-docstring,missing-class-docstring
# D-Bus method/signal names are PascalCase by protocol convention (SNI spec).
# Unused signal handler args (iface, invalidated, job_id, x, y …) are fixed
# by the dbus-python decorator signatures and cannot be renamed or removed.
"""
llama-cpp-tray — StatusNotifierItem (SNI) tray daemon for the llama-cpp systemd service.

Registers as a KDE/freedesktop system-tray icon via the SNI D-Bus protocol.
Left-click toggles the llama-cpp.service (start when inactive, stop when active).
Icon and tooltip reflect live service state, updated by subscribing to systemd's
PropertiesChanged signal on the system bus.

Dependencies: python3, dbus-python, dbus-glib (GLib main loop for dbus-python).
No GUI toolkit required — pure D-Bus, works on KDE Wayland natively.
"""

import os
import signal
import sys

import dbus  # pylint: disable=import-error
import dbus.mainloop.glib  # pylint: disable=import-error
import dbus.service  # pylint: disable=import-error
from gi.repository import GLib  # pylint: disable=import-error

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SERVICE_NAME = "llama-cpp.service"
UNIT_PATH = "/org/freedesktop/systemd1/unit/llama_2dcpp_2eservice"
SYSTEMD_DEST = "org.freedesktop.systemd1"
SYSTEMD_PATH = "/org/freedesktop/systemd1"

SNI_IFACE = "org.kde.StatusNotifierItem"
SNW_DEST = "org.kde.StatusNotifierWatcher"
SNW_PATH = "/StatusNotifierWatcher"

# Icon names matching the SVGs installed to ~/.local/share/icons/hicolor/scalable/apps/.
# Each variant has the status dot baked into the SVG so KDE shows it directly.
# KDE additionally dims the icon when Status=Passive (stopped state).
ICON_INACTIVE = "llama-cpp-tray"  # plain robot, no dot
ICON_ACTIVE = "llama-cpp-tray-active"  # robot + green dot  (#42be65)
ICON_ATTENTION = "llama-cpp-tray-attention"  # robot + lightpink dot (#ff7eb6)

# ---------------------------------------------------------------------------
# SNI D-Bus service object
# ---------------------------------------------------------------------------
SNI_INTROSPECT_XML = """
<!DOCTYPE node PUBLIC
  "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
  "http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node>
  <interface name="org.kde.StatusNotifierItem">
    <property name="Id"              type="s" access="read"/>
    <property name="Category"        type="s" access="read"/>
    <property name="Status"          type="s" access="read"/>
    <property name="Title"           type="s" access="read"/>
    <property name="IconName"        type="s" access="read"/>
    <property name="AttentionIconName" type="s" access="read"/>
    <property name="ToolTip"         type="(sa(iiay)ss)" access="read"/>
    <property name="Menu"            type="o" access="read"/>
    <method name="Activate">
      <arg direction="in" type="i" name="x"/>
      <arg direction="in" type="i" name="y"/>
    </method>
    <method name="SecondaryActivate">
      <arg direction="in" type="i" name="x"/>
      <arg direction="in" type="i" name="y"/>
    </method>
    <method name="ContextMenu">
      <arg direction="in" type="i" name="x"/>
      <arg direction="in" type="i" name="y"/>
    </method>
    <signal name="NewStatus">
      <arg type="s" name="status"/>
    </signal>
    <signal name="NewIcon"/>
    <signal name="NewToolTip"/>
  </interface>
</node>
"""


class LlamaTrayItem(dbus.service.Object):
    def __init__(self, bus, path, system_bus):
        super().__init__(bus, path)
        self._session_bus = bus
        self._system_bus = system_bus
        self._active_state = "unknown"
        self._refresh_state()
        self._subscribe_systemd()

    # -----------------------------------------------------------------------
    # State helpers
    # -----------------------------------------------------------------------

    def _refresh_state(self):
        """Read ActiveState from systemd over the system bus."""
        try:
            manager = self._system_bus.get_object(SYSTEMD_DEST, SYSTEMD_PATH)
            # LoadUnit ensures the unit object exists even when inactive
            unit_path = manager.LoadUnit(
                SERVICE_NAME,
                dbus_interface=f"{SYSTEMD_DEST}.Manager",
            )
            unit = self._system_bus.get_object(SYSTEMD_DEST, str(unit_path))
            props = dbus.Interface(unit, "org.freedesktop.DBus.Properties")
            state = str(props.Get(f"{SYSTEMD_DEST}.Unit", "ActiveState"))
            self._set_state(state)
        except dbus.DBusException as e:
            print(f"[llama-cpp-tray] state refresh error: {e}", file=sys.stderr)
            self._set_state("unknown")

    def _set_state(self, state):
        if state == self._active_state:
            return
        self._active_state = state
        self.NewStatus(self._sni_status())
        self.NewIcon()
        self.NewToolTip()

    def _sni_status(self):
        """Map systemd ActiveState -> SNI Status string.

        Active   — service running, icon shown at full brightness in main tray.
        NeedsAttention — transitioning (start/stop), draws attention briefly.
        Passive  — stopped/unknown; KDE dims and moves to overflow. The item
                   is still reachable via the tray's show-hidden chevron, and
                   the user can pin it to the main row via tray preferences.
        """
        if self._active_state == "active":
            return "Active"
        if self._active_state in ("activating", "deactivating"):
            return "NeedsAttention"
        return "Passive"

    def _tooltip_text(self):
        labels = {
            "active": "LLaMA server running — click to stop",
            "activating": "LLaMA server starting…",
            "deactivating": "LLaMA server stopping…",
            "inactive": "LLaMA server stopped — click to start",
            "failed": "LLaMA server failed — click to restart",
            "unknown": "LLaMA server state unknown",
        }
        return labels.get(self._active_state, f"llama-cpp: {self._active_state}")

    # -----------------------------------------------------------------------
    # Systemd signal subscription
    # -----------------------------------------------------------------------

    def _subscribe_systemd(self):
        """Subscribe to PropertiesChanged on the unit object (system bus)."""
        try:
            manager = self._system_bus.get_object(SYSTEMD_DEST, SYSTEMD_PATH)
            manager.Subscribe(dbus_interface=f"{SYSTEMD_DEST}.Manager")
        except dbus.DBusException:
            pass  # already subscribed or not needed

        self._system_bus.add_signal_receiver(
            handler_function=self._on_props_changed,
            signal_name="PropertiesChanged",
            dbus_interface="org.freedesktop.DBus.Properties",
            bus_name=SYSTEMD_DEST,
            path=UNIT_PATH,
        )
        # Also catch unit-not-yet-loaded case: listen for UnitNew/JobRemoved
        self._system_bus.add_signal_receiver(
            handler_function=self._on_job_removed,
            signal_name="JobRemoved",
            dbus_interface=f"{SYSTEMD_DEST}.Manager",
            bus_name=SYSTEMD_DEST,
            path=SYSTEMD_PATH,
        )

    def _on_props_changed(
        self, iface, changed, invalidated
    ):  # pylint: disable=unused-argument
        if "ActiveState" in changed:
            self._set_state(str(changed["ActiveState"]))

    def _on_job_removed(
        self, job_id, job_path, unit_name, result
    ):  # pylint: disable=unused-argument
        if unit_name == SERVICE_NAME:
            self._refresh_state()

    # -----------------------------------------------------------------------
    # Toggle action
    # -----------------------------------------------------------------------

    def _toggle(self):
        try:
            manager = self._system_bus.get_object(SYSTEMD_DEST, SYSTEMD_PATH)
            iface = f"{SYSTEMD_DEST}.Manager"
            if self._active_state in ("active", "activating"):
                manager.StopUnit(SERVICE_NAME, "replace", dbus_interface=iface)
            else:
                manager.StartUnit(SERVICE_NAME, "replace", dbus_interface=iface)
        except dbus.DBusException as e:
            print(f"[llama-cpp-tray] toggle error: {e}", file=sys.stderr)

    # -----------------------------------------------------------------------
    # org.kde.StatusNotifierItem properties (via GetAll / introspection)
    # -----------------------------------------------------------------------

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v"
    )
    def Get(self, interface, prop):
        return self.GetAll(interface)[prop]

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface):  # pylint: disable=unused-argument
        if self._active_state == "active":
            icon_name = ICON_ACTIVE
        elif self._active_state in ("activating", "deactivating"):
            icon_name = ICON_ATTENTION
        else:
            icon_name = ICON_INACTIVE
        return {
            "Id": dbus.String("llama-cpp-tray"),
            "Category": dbus.String("ApplicationStatus"),
            "Status": dbus.String(self._sni_status()),
            "Title": dbus.String("LLaMA Server"),
            "IconName": dbus.String(icon_name),
            "AttentionIconName": dbus.String(ICON_ATTENTION),
            "ToolTip": dbus.Struct(
                (
                    dbus.String(""),  # icon name for tooltip (unused)
                    dbus.Array([], signature="(iiay)"),  # icon pixmap
                    dbus.String("LLaMA Server"),  # title
                    dbus.String(self._tooltip_text()),  # body
                ),
                signature="(sa(iiay)ss)",
            ),
            "Menu": dbus.ObjectPath("/NO_DBUSMENU"),
        }

    @dbus.service.method("org.freedesktop.DBus.Introspectable", out_signature="s")
    def Introspect(self):
        return SNI_INTROSPECT_XML

    # -----------------------------------------------------------------------
    # org.kde.StatusNotifierItem methods
    # -----------------------------------------------------------------------

    @dbus.service.method(SNI_IFACE, in_signature="ii")
    def Activate(self, x, y):  # pylint: disable=unused-argument
        self._toggle()

    @dbus.service.method(SNI_IFACE, in_signature="ii")
    def SecondaryActivate(self, x, y):  # pylint: disable=unused-argument
        self._toggle()

    @dbus.service.method(SNI_IFACE, in_signature="ii")
    def ContextMenu(self, x, y):  # pylint: disable=unused-argument
        # No dbusmenu implemented — left/right click both toggle
        self._toggle()

    # -----------------------------------------------------------------------
    # org.kde.StatusNotifierItem signals
    # -----------------------------------------------------------------------

    @dbus.service.signal(SNI_IFACE, signature="s")
    def NewStatus(self, status):
        pass

    @dbus.service.signal(SNI_IFACE)
    def NewIcon(self):
        pass

    @dbus.service.signal(SNI_IFACE)
    def NewToolTip(self):
        pass


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    session_bus = dbus.SessionBus()
    system_bus = dbus.SystemBus()

    # Claim a unique well-known name on the session bus.
    # SNI spec: bus name must be org.kde.StatusNotifierItem-<pid>-<n>
    pid = os.getpid()
    bus_name_str = f"org.kde.StatusNotifierItem-{pid}-1"
    item_path = "/StatusNotifierItem"

    # These objects must stay alive for the duration of the process:
    # bus_name holds the D-Bus name reservation; item owns the object path.
    # Store in a list so pylint doesn't flag them as unused variables.
    _keep_alive = [
        dbus.service.BusName(bus_name_str, bus=session_bus),
        LlamaTrayItem(session_bus, item_path, system_bus),
    ]

    # Register with the StatusNotifierWatcher
    try:
        watcher = session_bus.get_object(SNW_DEST, SNW_PATH)
        watcher.RegisterStatusNotifierItem(
            bus_name_str,
            dbus_interface="org.kde.StatusNotifierWatcher",
        )
    except dbus.DBusException as e:
        print(f"[llama-cpp-tray] could not register with watcher: {e}", file=sys.stderr)
        sys.exit(1)

    loop = GLib.MainLoop()
    signal.signal(signal.SIGTERM, lambda *_: loop.quit())
    signal.signal(signal.SIGINT, lambda *_: loop.quit())

    print(f"[llama-cpp-tray] registered as {bus_name_str}", flush=True)
    loop.run()


if __name__ == "__main__":
    main()
