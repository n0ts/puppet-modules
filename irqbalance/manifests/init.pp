#
# irqbalance module
#

class irqbalance {
    if $processorcount > 2 {
        package { "irqbalance": }

        service { "irqbalance":
            require => Package["irqbalance"],
        }
    }
}
