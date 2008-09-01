#
# irqbalance module
#

class irqbalance {
    case $processcount {
        1:        {}
        default : {
            package { "irqbalance": }
            service { "irqbalance":
                require => Package["irqbalance"],
            }
        }
    }
}
