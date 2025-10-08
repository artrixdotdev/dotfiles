#!/usr/bin/env nu

# wl-gammarelay-rs CLI - Control display gamma, brightness, and temperature

# Check if required commands are installed
def check-dependencies [] {
    if (which wl-gammarelay-rs | is-empty) {
        error make {
            msg: "wl-gammarelay-rs is not installed"
            label: {
                text: "Please install wl-gammarelay-rs first"
                span: (metadata $env).span
            }
        }
    }

    if (which busctl | is-empty) {
        error make {
            msg: "busctl is not installed"
            label: {
                text: "Please install systemd (busctl) first"
                span: (metadata $env).span
            }
        }
    }
}

# Get list of available outputs
def get-outputs [] {
    try {
    busctl --user tree rs.wl-gammarelay
  | lines
  | str replace -ra '^[^/]* ' ''   # remove leading "│  ", "├─ ", "└─ ", etc.
  | where $it =~ '^/outputs/'
  | str trim
    } catch {
        []
    }
}

# Custom completer for output parameter
export def output [] {
    get-outputs
}

# Validate output selection
def validate-output [output: string] {
    let outputs = (get-outputs)

    if ($outputs | is-empty) {
        error make {
            msg: "No outputs found"
            label: {
                text: "Make sure wl-gammarelay-rs daemon is running"
            }
        }
    }

    if ($outputs | length) > 1 and $output == "/" {
        error make {
            msg: "Multiple outputs detected"
            label: {
                text: $"Please specify an output using --output flag. Available outputs: ($outputs | str join ', ')"
            }
        }
    }

    if $output != "/" and ($output not-in $outputs) {
        error make {
            msg: $"Output '($output)' not found"
            label: {
                text: $"Available outputs: ($outputs | str join ', ')"
            }
        }
    }
}

# Get the object path to use
def get-object-path [output: string] {
    if $output == "/" {
        "/"
    } else {
        $output
    }
}

# wl-gammarelay-rs CLI
def main [] {
    print "wl-gammarelay-rs CLI"
    print ""
    print "Usage:"
    print "  start                        - Start the daemon"
    print "  list                         - List available outputs"
    print "  brightness <amount>          - Adjust brightness"
    print "  brightness set <value>       - Set brightness"
    print "  gamma <amount>               - Adjust gamma"
    print "  gamma set <value>            - Set gamma"
    print "  temperature <amount>         - Adjust temperature"
    print "  temperature set <value>      - Set temperature"
    print "  invert                       - Toggle color inversion"
    print "  status                       - Show current values"
    print "  watch [format]               - Watch for changes"
    print ""
    print "Use --json flag for JSON output on most commands"
    print "Use --output/-o flag to specify output for multi-monitor setups"
}

# List available outputs
export def "main list" [
    --json  # Output as JSON
] {
    check-dependencies

    let outputs = (get-outputs)

    if $json {
        {outputs: $outputs} | to json
    } else {
        if ($outputs | is-empty) {
            print "No outputs found. Make sure wl-gammarelay-rs daemon is running."
        } else {
            print "Available outputs:"
            for output in $outputs {
                print $"  ($output)"
            }
        }
    }
}

# Start the wl-gammarelay-rs daemon
export def "main start" [
    --json  # Output as JSON
] {
    check-dependencies

    wl-gammarelay-rs &

    if $json {
        {status: "started", daemon: "wl-gammarelay-rs"} | to json
    } else {
        print "Starting wl-gammarelay-rs daemon..."
    }
}

# Update brightness by a relative amount
export def "main brightness" [
    amount: float  # Amount to change brightness by (e.g., 0.1 for +10%, -0.1 for -10%)
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user -- call rs.wl-gammarelay $path rs.wl.gammarelay UpdateBrightness d $amount

    if $json {
        {action: "update", property: "brightness", change: $amount, change_percent: ($amount * 100), output: $path} | to json
    } else {
        print $"Brightness updated by ($amount * 100)% on ($path)"
    }
}

# Set brightness to an absolute value
export def "main brightness set" [
    value: float  # Brightness value (0.0 to 1.0, where 1.0 = 100%)
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user set-property rs.wl-gammarelay $path rs.wl.gammarelay Brightness d $value

    if $json {
        {action: "set", property: "brightness", value: $value, value_percent: ($value * 100), output: $path} | to json
    } else {
        print $"Brightness set to ($value * 100)% on ($path)"
    }
}

# Update gamma by a relative amount
export def "main gamma" [
    amount: float  # Amount to change gamma by (e.g., 0.1 for +0.1, -0.1 for -0.1)
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user -- call rs.wl-gammarelay $path rs.wl.gammarelay UpdateGamma d $amount

    if $json {
        {action: "update", property: "gamma", change: $amount, output: $path} | to json
    } else {
        print $"Gamma updated by ($amount) on ($path)"
    }
}

# Set gamma to an absolute value
export def "main gamma set" [
    value: float  # Gamma value (typically 0.5 to 2.0, default 1.0)
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user set-property rs.wl-gammarelay $path rs.wl.gammarelay Gamma d $value

    if $json {
        {action: "set", property: "gamma", value: $value, output: $path} | to json
    } else {
        print $"Gamma set to ($value) on ($path)"
    }
}

# Update temperature by a relative amount
export def "main temperature" [
    amount: int  # Amount to change temperature by (e.g., 100 for +100K, -100 for -100K)
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user -- call rs.wl-gammarelay $path rs.wl.gammarelay UpdateTemperature n $amount

    if $json {
        {action: "update", property: "temperature", change: $amount, output: $path} | to json
    } else {
        print $"Temperature updated by ($amount)K on ($path)"
    }
}

# Set temperature to an absolute value
export def "main temperature set" [
    value: int  # Temperature value in Kelvin (1000 to 10000, default 6500)
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user set-property rs.wl-gammarelay $path rs.wl.gammarelay Temperature q $value

    if $json {
        {action: "set", property: "temperature", value: $value, output: $path} | to json
    } else {
        print $"Temperature set to ($value)K on ($path)"
    }
}

# Toggle inverted colors
export def "main invert" [
    --output (-o): string@output = "/"  # Output to modify
    --json  # Output as JSON
] {
    check-dependencies
    validate-output $output

    let path = (get-object-path $output)
    busctl --user -- call rs.wl-gammarelay $path rs.wl.gammarelay ToggleInverted

    if $json {
        {action: "toggle", property: "inverted", output: $path} | to json
    } else {
        print $"Inverted colors toggled on ($path)"
    }
}

# Get current values
export def "main status" [
    --output (-o): string@output = "/"  # Output to query
    --json  # Output as JSON
    --all  # Show status for all outputs individually
] {
    check-dependencies

    if $all {
        let outputs = (get-outputs)

        if ($outputs | is-empty) {
            if $json {
                {error: "No outputs found"} | to json
            } else {
                print "No outputs found. Make sure wl-gammarelay-rs daemon is running."
            }
            return
        }

        let all_status = ($outputs | each {|out|
            let brightness = (busctl --user get-property rs.wl-gammarelay $out rs.wl.gammarelay Brightness | awk '{print $2}' | into float)
            let gamma = (busctl --user get-property rs.wl-gammarelay $out rs.wl.gammarelay Gamma | awk '{print $2}' | into float)
            let temperature = (busctl --user get-property rs.wl-gammarelay $out rs.wl.gammarelay Temperature | awk '{print $2}' | into int)
            let inverted = (busctl --user get-property rs.wl-gammarelay $out rs.wl.gammarelay Inverted | awk '{print $2}')

            {
                output: $out,
                brightness: $brightness,
                brightness_percent: ($brightness * 100),
                gamma: $gamma,
                temperature: $temperature,
                inverted: $inverted
            }
        })

        if $json {
            {outputs: $all_status} | to json
        } else {
            for item in $all_status {
                print $"Output: ($item.output)"
                print $"  Brightness:  ($item.brightness_percent)%"
                print $"  Gamma:       ($item.gamma)"
                print $"  Temperature: ($item.temperature)K"
                print $"  Inverted:    ($item.inverted)"
                print ""
            }
        }
    } else {
        validate-output $output
        let path = (get-object-path $output)

        let brightness = (busctl --user get-property rs.wl-gammarelay $path rs.wl.gammarelay Brightness | awk '{print $2}' | into float)
        let gamma = (busctl --user get-property rs.wl-gammarelay $path rs.wl.gammarelay Gamma | awk '{print $2}' | into float)
        let temperature = (busctl --user get-property rs.wl-gammarelay $path rs.wl.gammarelay Temperature | awk '{print $2}' | into int)
        let inverted = (busctl --user get-property rs.wl-gammarelay $path rs.wl.gammarelay Inverted | awk '{print $2}')

        if $json {
            {
                output: $path,
                brightness: $brightness,
                brightness_percent: ($brightness * 100),
                gamma: $gamma,
                temperature: $temperature,
                inverted: $inverted
            } | to json
        } else {
            print $"Output: ($path)"
            print $"  Brightness:  ($brightness * 100)%"
            print $"  Gamma:       ($gamma)"
            print $"  Temperature: ($temperature)K"
            print $"  Inverted:    ($inverted)"
        }
    }
}

# Watch for changes with custom format
export def "main watch" [
    format: string = "{t}K {bp}% γ{g}"  # Format string ({t}=temp, {b}=brightness, {bp}=brightness%, {g}=gamma)
] {
    check-dependencies
    wl-gammarelay-rs watch $format
}
