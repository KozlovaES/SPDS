

            .text

start:      move    $t0, $0
            li      $t1, 1
			li		$t2, 7
            move    $v0, $t0

fibonacci:	move	$a0, $t1
            addu    $t1, $t0, $t1
			move	$t0, $a0
			addiu	$t2, -1
			beqz	$t2, out
            b       fibonacci

out:		move    $v0, $t1
			b		out