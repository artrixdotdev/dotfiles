pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Shared

Button {
   id: control

   enum Variant {
      Default,
      Secondary,
      Destructive,
      Outline,
      Ghost,
      Link
   }

   property var variant: BetterButton.Default

   property color accentColor: resolveAccentColor(variant)
   property color textColor: resolveTextColor(variant)
   property int radius: 6

   // Layout defaults

   focusPolicy: Qt.StrongFocus

   // === Core Color Resolution ===
   function resolveAccentColor(v) {
      // direct color support
      if (typeof v === "string") {
         let parsed = Qt.colorEqual(v, v) ? undefined : undefined;
         try {
            return Qt.color(v);
         } catch (e) {}
      }

      switch (v) {
      case BetterButton.Secondary:
         return Theme.colors.secondary_container;
      case BetterButton.Destructive:
         return Theme.colors.error_container;
      case BetterButton.Outline:
      case BetterButton.Ghost:
      case BetterButton.Link:
         return Theme.colors.surface_container_high;
      default:
         return Theme.colors.primary_container;
      }
   }

   function resolveTextColor(v) {
      if (typeof v === "string") {
         try {
            Qt.color(v);
            return Theme.colors.on_primary_container;
         } catch (e) {}
      }

      switch (v) {
      case BetterButton.Secondary:
         return Theme.colors.on_secondary_container;
      case BetterButton.Destructive:
         return Theme.colors.on_error_container;
      case BetterButton.Outline:
      case BetterButton.Ghost:
      case BetterButton.Link:
         return Theme.colors.on_surface;
      default:
         return Theme.colors.on_primary_container;
      }
   }

   background: Rectangle {
      id: bg
      radius: 6
      border.width: (control.variant === BetterButton.Outline) ? 1 : 0
      border.color: (control.variant === BetterButton.Outline) ? Theme.colors.outline : "transparent"

      color: (control.variant === BetterButton.Ghost || control.variant === BetterButton.Link) ? "transparent" : (control.down ? Qt.darker(control.accentColor, 1.2) : control.accentColor)

      Behavior on color {
         ColorAnimation {
            duration: 110
            easing.type: Easing.OutQuad
         }
      }
   }

   contentItem: Text {
      text: control.text
      anchors.centerIn: parent
      font.pixelSize: 15
      color: (control.variant === BetterButton.Link) ? Theme.colors.primary : control.textColor
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
   }

   layer.enabled: control.hovered || control.activeFocus
   layer.effect: MultiEffect {
      source: bg
      shadowEnabled: control.hovered
      shadowColor: Theme.colors.shadow
      shadowBlur: 12
      brightness: control.hovered ? 0.05 : 0
      // shadowOffsetY: 4
   }

   // cursorShape: Qt.PointingHandCursor
}
