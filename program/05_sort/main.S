# Insertion sorting algorithm
# The first element is A[1]
# for j = 2 to A.length do 
#     key = A[j]
#     i = j - 1
#     while (i > 0 and A[i] < key) do 
#         A[i + 1] = A[i]
#         i = i - 1
#     end while
#     A[i+1] = key
# end for

            .text

start:		
			li		$t0, 1				# for-loop counter 			(j)
            li		$t1, 16				# Amount of words to sort	(n)

loop_for:	
			lw		$t3, 0($t0)			# key = A[j]
			li		$t2, 1
			subu	$t4, $t0, $t2		# i = j - 1

loop_while:
			# "while" loop condition
			bgez	$t4, continue		# i >= 0
			b		end_while

continue:
			lw		$t5, 0($t4)			# A[i]
			sltu	$t2, $t5, $t3		# A[i] < key
			beq		$t2, $0, end_while	
			addiu	$t2, $t4, 1
			sw		$t5, 0($t2)			# A[i + 1] = A[i]

			li		$t2, 1
			subu	$t4, $t4, $t2		# i = i - 1
			b		loop_while

end_while:	
			addiu	$t2, $t4, 1
			sw		$t3, 0($t2)			# A[i + 1] = key

			# "for" loop condition checking and iterator increment
			addiu	$t0, 1				# j = j + 1
			bne		$t0, $t1, loop_for	# j < n

end_for:	
			b		end_for
