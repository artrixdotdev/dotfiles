# Battery detection for NeoWall's visibility controller.
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
