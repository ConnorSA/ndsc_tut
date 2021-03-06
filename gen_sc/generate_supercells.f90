 MODULE constants
!--------------------------------------------------------------!
! Numerical constants and constants for variable declarations. !
!--------------------------------------------------------------!
 IMPLICIT NONE
 INTEGER,PARAMETER :: dp=kind(1.d0)
 END MODULE constants


 MODULE utils
!--------------------------!
! Miscellaneous utilities. !
!--------------------------!
 USE constants
 IMPLICIT NONE
 
 CONTAINS

 INTEGER FUNCTION gcd(int_1,int_2)
!----------------------------------------------------------------------!
! Calculate the greatest common divisor of two positive integers using !
! Euclid's algorithm.                                                  !
!----------------------------------------------------------------------!
 IMPLICIT NONE
 INTEGER,INTENT(in) :: int_1,int_2
 INTEGER :: a,b,temp

 a=int_1 ; b=int_2

 if(a<b)then
  temp=a
  a=b
  b=temp
 endif ! a<b

 do
  temp=mod(a,b)
  if(temp==0)exit
  a=b
  b=temp
 enddo

 gcd=b

 END FUNCTION gcd


 CHARACTER(12) FUNCTION i2s(n)
!------------------------------------------------------------------------------!
! Convert integers to left justified strings that can be printed in the middle !
! of a sentence without introducing large amounts of white space.              !
!------------------------------------------------------------------------------!
 IMPLICIT NONE
 INTEGER,INTENT(in) :: n
 INTEGER :: i,j
 INTEGER,PARAMETER :: ichar0=ICHAR('0')

 i2s=''
 i=abs(n)
 do j=len(i2s),1,-1
  i2s(j:j)=achar(ichar0+mod(i,10))
  i=i/10
  if(i==0)exit
 enddo ! j
 if(n<0)then
  i2s='-'//adjustl(i2s)
 else
  i2s=adjustl(i2s)
 endif ! n<0

 END FUNCTION i2s


 LOGICAL FUNCTION reduce_vec(vecs)
!------------------------------------------------------------------------------!
! Given three linearly independent input vectors a, b and c, construct the     !
! following linear combinations: a+b-c, a-b+c, -a+b+c, a+b+c and  check if any !
! of the four new vectors is shorter than any of a, b or c. If so, replace the !
! longest of a, b and c with the new (shorter) vector. The resulting three     !
! vectors are also linearly independent.                                       !
!------------------------------------------------------------------------------!
 IMPLICIT NONE
 REAL(dp),INTENT(inout) :: vecs(3,3)
 REAL(dp),PARAMETER :: tol_zero=1.d-7
 INTEGER :: longest,i
 REAL(dp) :: newvecs(4,3),maxlen,nlen

! Determine which of the three input vectors is the longest
 maxlen=0
 DO i=1,3
  nlen=vecs(i,1)**2+vecs(i,2)**2+vecs(i,3)**2
! Test nlen>maxlen within some tolerance to avoid floating point problems
  IF(nlen-maxlen>tol_zero*maxlen)THEN
   maxlen=nlen
   longest=i
  ENDIF
 ENDDO ! i

! Construct the four linear combinations
 newvecs(1,1:3)=vecs(1,1:3)+vecs(2,1:3)-vecs(3,1:3)
 newvecs(2,1:3)=vecs(1,1:3)-vecs(2,1:3)+vecs(3,1:3)
 newvecs(3,1:3)=-vecs(1,1:3)+vecs(2,1:3)+vecs(3,1:3)
 newvecs(4,1:3)=vecs(1,1:3)+vecs(2,1:3)+vecs(3,1:3)

! Check if any of the four new vectors is shorter than longest input vector
 reduce_vec=.FALSE.
 DO i=1,4
  nlen=newvecs(i,1)**2+newvecs(i,2)**2+newvecs(i,3)**2
  IF(nlen-maxlen<-tol_zero*maxlen)THEN
   vecs(longest,1:3)=newvecs(i,1:3)
   reduce_vec=.TRUE.
   EXIT
  ENDIF
 ENDDO ! i

 END FUNCTION reduce_vec


 FUNCTION determinant33(A)
!-----------------------------------------------------!
! Given a 3x3 matrix A, this function returns det(A). !
!-----------------------------------------------------!
 IMPLICIT NONE
 REAL(dp),INTENT(in) :: A(3,3)
 REAL(dp) :: determinant33

 determinant33=A(1,1)*(A(2,2)*A(3,3)-A(3,2)*A(2,3))&
  &+A(1,2)*(A(3,1)*A(2,3)-A(2,1)*A(3,3))&
  &+A(1,3)*(A(2,1)*A(3,2)-A(3,1)*A(2,2))

 END FUNCTION determinant33


 SUBROUTINE supercells_generator(num_pcells,num_hnf,hnf)
!------------------------------------------------------------------------------!
! Generate all unique supercells that contain a given number of primitive unit !
! cells. See 'Hart and Forcade, Phys. Rev. B 77, 224115 (2008)' for details of !
! the algorithm.                                                               !
!------------------------------------------------------------------------------!
 IMPLICIT NONE
 INTEGER,INTENT(in) :: num_pcells
 INTEGER,INTENT(out) :: num_hnf
 INTEGER,POINTER :: hnf(:,:,:)
 INTEGER :: a,b,c,d,e,f,ialloc,count_hnf,quotient

 count_hnf=0

 do a=1,num_pcells 
  if(.not.mod(num_pcells,a)==0)cycle
  quotient=num_pcells/a
  do c=1,quotient  
   if(.not.mod(quotient,c)==0)cycle
   f=quotient/c
   count_hnf=count_hnf+c*f**2
  enddo ! c
 enddo ! a

 num_hnf=count_hnf
 count_hnf=0

 allocate(hnf(3,3,num_hnf),stat=ialloc)
 if(ialloc/=0)then
  write(*,*)'Problem allocating hnf array in supercells_generator.'
  stop
 endif

 hnf(1:3,1:3,1:num_hnf)=0

 do a=1,num_pcells 
  if(.not.mod(num_pcells,a)==0)cycle
  quotient=num_pcells/a
  do c=1,quotient  
   if(.not.mod(quotient,c)==0)cycle
   f=quotient/c
   do b=0,c-1
    do d=0,f-1
     do e=0,f-1
      count_hnf=count_hnf+1
      hnf(1,1,count_hnf)=a
      hnf(1,2,count_hnf)=b
      hnf(2,2,count_hnf)=c
      hnf(1,3,count_hnf)=d
      hnf(2,3,count_hnf)=e
      hnf(3,3,count_hnf)=f
     enddo ! e
    enddo ! d
   enddo ! b
  enddo ! c
 enddo ! a

 if(count_hnf/=num_hnf)then
  write(*,*)'Did not generate all HNF matrices.'
  stop
 endif 
 
 END SUBROUTINE supercells_generator


 SUBROUTINE minkowski_reduce(vecs)
!-----------------------------------------------------------------------------!
! Given n vectors a(i) that form a basis for a lattice L in n dimensions, the ! 
! a(i) are said to be Minkowski-reduced if the following conditions are met:  !
!                                                                             !
! - a(1) is the shortest non-zero vector in L                                 !
! - for i>1, a(i) is the shortest possible vector in L such that a(i)>=a(i-1) !
!   and the set of vectors a(1) to a(i) are linearly independent              !
!                                                                             !
! In other words the a(i) are the shortest possible basis vectors for L. This !
! routine, given a set of input vectors a'(i) that are possibly not           !
! Minkowski-reduced, returns the vectors a(i) that are.                       !
!-----------------------------------------------------------------------------!
 IMPLICIT NONE
 REAL(dp),INTENT(inout) :: vecs(3,3)
 INTEGER :: i
 REAL(dp) :: tempvec(3,3)
 LOGICAL :: changed

 iter: DO
  tempvec=vecs
  DO i=1,3
! First check linear combinations involving two vectors
   vecs(i,1:3)=0
   changed=reduce_vec(vecs)
   vecs(i,1:3)=tempvec(i,1:3)
   IF(changed)CYCLE iter
  ENDDO ! i
! Then check linear combinations involving all three
  IF(reduce_vec(vecs))CYCLE
  EXIT
 ENDDO iter

 END SUBROUTINE minkowski_reduce


 SUBROUTINE inv33(v,inv)
!-----------------------!
! Inverts 3x3 matrices. !
!-----------------------!
 IMPLICIT NONE
 REAL(dp),INTENT(in) :: v(3,3)
 REAL(dp),INTENT(out) :: inv(3,3)
 REAL(dp) :: d

 d=determinant33(v)
 if(d==0.d0)then
  write(*,*)'Trying to invert a singular determinant.'
  stop
 endif ! d
 d=1.d0/d
 inv(1,1)=(v(2,2)*v(3,3)-v(2,3)*v(3,2))*d
 inv(1,2)=(v(3,2)*v(1,3)-v(1,2)*v(3,3))*d
 inv(1,3)=(v(1,2)*v(2,3)-v(1,3)*v(2,2))*d
 inv(2,1)=(v(3,1)*v(2,3)-v(2,1)*v(3,3))*d
 inv(2,2)=(v(1,1)*v(3,3)-v(3,1)*v(1,3))*d
 inv(2,3)=(v(2,1)*v(1,3)-v(1,1)*v(2,3))*d
 inv(3,1)=(v(2,1)*v(3,2)-v(2,2)*v(3,1))*d
 inv(3,2)=(v(3,1)*v(1,2)-v(1,1)*v(3,2))*d
 inv(3,3)=(v(1,1)*v(2,2)-v(1,2)*v(2,1))*d

 END SUBROUTINE inv33

 END MODULE utils


 PROGRAM generate_supercells
!---------------------!
! GENERATE_SUPERCELLS !
!---------------------!
 USE utils
 IMPLICIT NONE
 REAL(dp),PARAMETER :: tol=1.d-10
 INTEGER,ALLOCATABLE :: int_kpoints(:,:),numerator(:,:),denominator(:,:),&
  &super_size(:),label(:)
 INTEGER :: i,j,k,p,q,r,grid(1:3),ialloc,ierr,istat,lcm,num_kpoints,count,&
  &s11,s12,s13,s22,s23,s33,quotient,hnf(3,3),size_count
 REAL(dp),ALLOCATABLE :: kpoints(:,:)
 REAL(dp) :: prim_latt_vecs(3,3),rec_latt_vecs(3,3),temp_latt_vecs(3,3),&
  &temp_scell(3,3),prim(3)
 LOGICAL,ALLOCATABLE :: found_kpoint(:)
 LOGICAL :: found

! Get the primitive cell lattice vectors
 open(unit=11,file='prim.dat',status='old',iostat=ierr)
 if(ierr/=0)then
  write(*,*)'Problem opening prim.dat file.'
  stop
 endif ! ierr
 read(11,*,iostat=ierr)prim_latt_vecs(1,1:3)
 if(ierr==0)read(11,*,iostat=ierr)prim_latt_vecs(2,1:3)
 if(ierr==0)read(11,*,iostat=ierr)prim_latt_vecs(3,1:3)
 if(ierr/=0)then
  write(*,*)'Problem reading prim.dat file.'
  stop
 endif ! ierr
 close(11)

! Get the dimensions of the k-point grid
 open(unit=11,file='grid.dat',status='old',iostat=ierr)
 if(ierr/=0)then
  write(*,*)'Problem opening grid.dat file.'
  stop
 endif ! ierr
 read(11,*,iostat=ierr)grid(1:3)
 if(ierr/=0.or.any(grid(1:3)==0))then
  write(*,*)'Problem reading grid.dat file.'
  stop
 endif ! ierr
 close(11)

 call inv33(prim_latt_vecs,rec_latt_vecs)
 rec_latt_vecs=transpose(rec_latt_vecs)

! Get the number of k-points in the ibz.dat file
 call system("echo $(wc -l ibz.dat | awk '{print $1}') > tempfile.dat",istat)
 if(istat/=0)then
  write(*,*)'Problem counting the number of lines in ibz.dat.'
  stop
 endif
 open(unit=10,file='tempfile.dat',status='old',iostat=ierr)
 if(ierr/=0)then
  write(*,*)'Problem opening tempfile.dat.'
  stop
 endif
 read(10,*,iostat=ierr)num_kpoints
 if(ierr/=0)then
  write(*,*)'Problem reading tempfile.dat.'
  stop
 endif
 close(10,status='delete')

! Allocate some arrays
 allocate(kpoints(3,num_kpoints),stat=ialloc)
 if(ialloc/=0)then
  write(*,*)'Problem allocating kpoints array.'
  stop
 endif

! Read ibz.dat file
 open(unit=11,file='ibz.dat',status='old',iostat=ierr)
 if(ierr/=0)then
  write(*,*)'Problem opening ibz.dat.'
  stop
 endif ! ierr
 do i=1,num_kpoints
  read(11,*,iostat=ierr)kpoints(1:3,i)
  if(ierr/=0)then
   write(*,*)'Problem reading ibz.dat.'
   stop
  endif ! ierr
 enddo ! i
 close(11)

! Allocate some more arrays
 allocate(int_kpoints(3,num_kpoints),numerator(3,num_kpoints),&
  &denominator(3,num_kpoints),super_size(num_kpoints),&
  &found_kpoint(num_kpoints),label(num_kpoints),stat=ialloc)
 if(ialloc/=0)then
  write(*,*)'Problem allocating int_kpoints array.'
  stop
 endif ! ialloc

! Express k-points as fractions
 do i=1,num_kpoints
  found=.false.
  do p=-grid(1),grid(1)
   do q=-grid(2),grid(2)
    do r=-grid(3),grid(3)
     if(abs(dble(p)/dble(grid(1))-kpoints(1,i))<tol)then
      if(abs(dble(q)/dble(grid(2))-kpoints(2,i))<tol)then
       if(abs(dble(r)/dble(grid(3))-kpoints(3,i))<tol)then
        int_kpoints(1,i)=p
        int_kpoints(2,i)=q
        int_kpoints(3,i)=r
        found=.true.
       endif ! r      
      endif ! q
     endif ! p
     if(found)exit
    enddo ! r
    if(found)exit
   enddo ! q
   if(found)exit
  enddo ! p
  if(.not.found)then
   write(*,*)'Unable to find fractional representation of k-point.'
   stop
  endif ! found
 enddo ! i

 numerator(1:3,1:num_kpoints)=0
 denominator(1:3,1:num_kpoints)=1

! Reduce fractions
 do i=1,num_kpoints
  do j=1,3
   if(int_kpoints(j,i)/=0)then
    numerator(j,i)=int_kpoints(j,i)/gcd(abs(int_kpoints(j,i)),grid(j))
    denominator(j,i)=grid(j)/gcd(abs(int_kpoints(j,i)),grid(j))
   endif ! int_kpoints
  enddo ! j
  lcm=denominator(2,i)*denominator(3,i)/gcd(denominator(2,i),denominator(3,i))
  lcm=denominator(1,i)*lcm/gcd(denominator(1,i),lcm)
  super_size(i)=lcm
 enddo ! i

 found_kpoint(1:num_kpoints)=.false.
 label(1:num_kpoints)=0
 count=0

 open(unit=13,file='kpoint_to_supercell.dat',status='replace',iostat=ierr)
 if(ierr/=0)then
  write(*,*)'Problem opening kpoint_to_supercell.dat file.'
  stop
 endif ! ierr

 open(unit=14,file='ibz.dat',status='replace',iostat=ierr)
 if(ierr/=0)then
  write(*,*)'Problem opening ibz.dat file.'
  stop
 endif ! ierr

 do size_count=1,maxval(super_size(1:num_kpoints))
  do i=1,num_kpoints
   if(super_size(i)/=size_count)cycle
   if(found_kpoint(i))cycle
   do s11=1,super_size(i)
    if(.not.mod(super_size(i),s11)==0)cycle
    quotient=super_size(i)/s11
    do s22=1,quotient
     if(.not.mod(quotient,s22)==0)cycle
     s33=quotient/s22
     do s12=0,s22-1
      do s13=0,s33-1
       do s23=0,s33-1
        hnf(1:3,1:3)=0
        hnf(1,1)=s11 ; hnf(1,2)=s12 ; hnf(1,3)=s13
        hnf(2,2)=s22 ; hnf(2,3)=s23
        hnf(3,3)=s33
        temp_scell(1:3,1:3)=dble(hnf(1:3,1:3))
        do k=1,3
         prim(k)=sum(temp_scell(k,1:3)*kpoints(1:3,i))
        enddo ! k
        if(all(abs(prim(1:3)-dble(nint(prim(1:3))))<tol))then
         count=count+1
         found_kpoint(i)=.true.
         label(i)=count
         write(13,*)kpoints(1:3,i),label(i)
         write(14,*)kpoints(1:3,i)
         do j=i+1,num_kpoints
          if(found_kpoint(j))cycle
          if(super_size(j)/=super_size(i))cycle
          do k=1,3
           prim(k)=sum(temp_scell(k,1:3)*kpoints(1:3,j))
          enddo ! k
          if(all(abs(prim(1:3)-dble(nint(prim(1:3))))<tol))then
           found_kpoint(j)=.true.
           label(j)=count
           write(13,*)kpoints(1:3,j),label(j)
           write(14,*)kpoints(1:3,j)
          endif ! tol
         enddo ! j
         do k=1,3
          do j=1,3
           temp_latt_vecs(k,j)=sum(dble(hnf(k,1:3))*prim_latt_vecs(1:3,j))
          enddo ! j
         enddo ! k
         call minkowski_reduce(temp_latt_vecs)
         do k=1,3
          do j=1,3
           hnf(k,j)=nint(sum(temp_latt_vecs(k,1:3)*rec_latt_vecs(j,1:3)))  
          enddo ! j
         enddo ! k
         open(unit=12,file='supercell.'//trim(i2s(count))//'.dat',&
          &status='replace',iostat=ierr)
         if(ierr/=0)then
          write(*,*)'Problem opening supercell.'//trim(i2s(count))//'.dat file.'
          stop
         endif ! ierr
         write(12,*)hnf(1,1:3)
         write(12,*)hnf(2,1:3)
         write(12,*)hnf(3,1:3)
         close(12)
         open(unit=12,file='size.'//trim(i2s(count))//'.dat',&
          &status='replace',iostat=ierr)
         if(ierr/=0)then
          write(*,*)'Problem opening size.'//trim(i2s(count))//'.dat file.'
          stop
         endif ! ierr
         write(12,*)super_size(i)
         close(12)
        endif ! tol
        if(found_kpoint(i))exit
       enddo ! s23
       if(found_kpoint(i))exit
      enddo ! s13
      if(found_kpoint(i))exit
     enddo ! s12
     if(found_kpoint(i))exit
    enddo ! s22
    if(found_kpoint(i))exit
   enddo ! s11
  enddo ! i
 enddo ! size_count

 close(13) ; close(14)

 if(any(.not.found_kpoint(1:num_kpoints)))then
  write(*,*)'Unable to allocate each k-point to a supercell matrix.'
  stop
 endif ! found_kpoint

 END PROGRAM generate_supercells
