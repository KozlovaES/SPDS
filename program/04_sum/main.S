

            .text

start:      li     $s0, 0
            li     $s1, 0
            li     $v0, 0
            
square:     addu  $s1, $s1, 1
            addu  $s0, $s0, $s1
            move   $v0, $s0
            b      square
