

			.text

start:		li		$t0, 9
			li		$t1, 11
			move	$v0, $0

main:		nor		$t0, $t0, $t1 
			move 	$v0, $t0
			b		main

