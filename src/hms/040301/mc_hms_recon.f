	subroutine mc_hms_recon (delta_p,delta_t,delta_phi,y_tgt,fry)
C+______________________________________________________________________________
!
! MC_HMS_RECON : Reconstruct target quantities from tracks.
!		   This subroutine is part of the MC_HMS program.
!
! Right-handed coordinates are assumed: X=down, Z=downstream, Y = (Z cross X)
!
! Author: D. Potterveld, ANL, 18-Mar-1993
!
! Modification History:
!
!  19-AUG-1993	(DHP) Modified to use COSY INFINITY reconstruction coefficients.
C-______________________________________________________________________________
     
	implicit none

        include '../track.inc'

	integer*4 specnum
	parameter (specnum = 1)			!this is the HMS routine

C Argument definitions.

	real*8	delta_p,delta_t,delta_phi,y_tgt
	real*8	fry			!vertical position at target (+y=down)

C Cosy reconstruction matrix elements.

	integer*4 max_elements
	parameter (max_elements = 1000)

	integer*4 nspectr
	parameter (nspectr = 2)

	real*8		coeff(nspectr,4,max_elements)
	integer*2	expon(nspectr,5,max_elements)
	integer*4	n_terms(nspectr),max_order
	real*8		sum(4),hut(5),term

C Misc. variables.

	integer*4	i,j
	integer*4	chan

	logical	firsttime	/.true./
	character*132	line

C Functions.

	logical locforunt

C No amnesia, please...

	save

C ============================= Executable Code ================================

C First time through, read in coefficients from data file.

	if (firsttime) then
	  if (.not.locforunt(chan)) stop 'MC_HMS_RECON: No I/O channels!'
	  open (unit=chan,status='old',readonly,file='hms/recon_cosy.dat')

! Skip past header.

	  line = '!'
	  do while (line(1:1).eq.'!')
	    read (chan,1001) line
	  enddo

! Read in coefficients and exponents.

	  n_terms(specnum) = 0
	  max_order = 0
	  do while (line(1:4).ne.' ---')
	    n_terms(specnum) = n_terms(specnum) + 1
	    if (n_terms(specnum).gt.max_elements)
     >		stop 'WCRECON: too many COSY terms!'
	    read (line,1200) (coeff(specnum,i,n_terms(specnum)),i=1,4),
     >				(expon(specnum,j,n_terms(specnum)),j=1,5)
	    read (chan,1001) line
	    max_order = max(max_order, expon(specnum,1,n_terms(specnum)) + 
     >			expon(specnum,2,n_terms(specnum)) +
     >			expon(specnum,3,n_terms(specnum)) +
     >			expon(specnum,4,n_terms(specnum)) +
     >			expon(specnum,5,n_terms(specnum)))
	  enddo
!!	  write(6,*) 'HMS: N_TERMS, MAX_ORDER = ',n_terms(specnum),max_order
	  close (unit=chan)
	  firsttime = .false.
	endif

C Reset COSY sums.

	do i = 1,4
	  sum(i) = 0.
	enddo

C Convert hut quantities to right-handed coordinates, in meters and rad.
C Make sure hut(5) is non-zero, to avoid taking 0.0**0 (which crashes)

	hut(1) = xs/100.		!Units: meters
	hut(2) = dxdzs			!slope
	hut(3) = ys/100.		!Meters
	hut(4) = dydzs			!slope
	hut(5) = fry/100.		!vert. position at target
	if (abs(hut(5)).le.1.d-30) hut(5)=1.d-30

C Compute COSY sums.

	do i = 1,n_terms(specnum)
	  term =  hut(1)**expon(specnum,1,i) * hut(2)**expon(specnum,2,i)
     >		* hut(3)**expon(specnum,3,i) * hut(4)**expon(specnum,4,i)
     >		* hut(5)**expon(specnum,5,i)
	  sum(1) = sum(1) + term*coeff(specnum,1,i)
	  sum(2) = sum(2) + term*coeff(specnum,2,i)
	  sum(3) = sum(3) + term*coeff(specnum,3,i)
	  sum(4) = sum(4) + term*coeff(specnum,4,i)
	enddo
     
C Load output values.

	delta_phi = sum(1)		!slope
	y_tgt	  = sum(2)*100.		!cm
	delta_t   = sum(3)		!slope
	delta_p   = sum(4)*100.		!percent deviation
     
      return

C ============================ Format Statements ===============================

1001	format(a)
1200	format(1x,4g16.9,1x,5i1)

      END
