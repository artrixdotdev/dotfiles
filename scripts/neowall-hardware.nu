# Hardware facts shared by NeoWall startup and its visibility controller.
export def system-batteries [root: string = "/sys"] {
  glob ($root | path join "class/power_supply/*")
  | where {|supply|
    let type_file = ($supply | path join "type")
    let scope_file = ($supply | path join "scope")
    if not ($type_file | path exists) or (open $type_file | str trim) != "Battery" {
      false
    } else if ($scope_file | path exists) {
      (open $scope_file | str trim) != "Device"
    } else {
      true
    }
  }
}

export def gpu-count [root: string = "/sys"] {
  # PCI display-class devices include integrated, discrete, and 3D controllers,
  # even when a GPU has no active DRM card. Virtual/simpledrm cards are excluded.
  let pci_gpus = (glob ($root | path join "bus/pci/devices/*")
    | where {|device|
      let class_file = ($device | path join "class")
      ($class_file | path exists) and ((open $class_file | str trim | str lowercase) =~ '^0x03')
    }
    | each { path expand })

  # Include platform GPUs exposed through DRM, then deduplicate PCI devices.
  let drm_gpus = (glob ($root | path join "class/drm/card[0-9]*")
    | where {|card| ($card | path basename) =~ '^card[0-9]+$' }
    | where {|card|
      let driver = ($card | path join "device/driver")
      ($driver | path exists) and (($driver | path expand | path basename) not-in ["simpledrm" "simple-framebuffer" "vgem"])
    }
    | each {|card| $card | path join "device" | path expand })

  $pci_gpus | append $drm_gpus | uniq | length
}
