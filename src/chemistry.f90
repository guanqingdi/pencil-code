! $Id: chemistry.f90,v 1.28 2008-03-17 14:35:14 nbabkovs Exp $
!  This modules addes chemical species and reactions.

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lchemistry = .true.
!
! MVAR CONTRIBUTION 1
! MAUX CONTRIBUTION 0
!
! PENCILS PROVIDEDgTT,mu1,gamma,gamma1,gamma11,gradcp,cv,cv1,cp,cp1,lncp,mu1,H0RT,S0R
!***************************************************************

module Chemistry

  use Cparam
  use Cdata
  use Messages
  use Sub, only: keep_compiler_quiet


  implicit none

  include 'chemistry.h'
!
!  parameters related to chemical reactions
!
  logical :: lreactions=.true.,lkreactions_profile=.false.
  integer :: nreactions=0,nreactions1=0,nreactions2=0
  real, dimension(2*nchemspec) :: kreactions_profile_width=0.

  integer :: mreactions
  integer, allocatable, dimension(:,:) :: stoichio,Sijm,Sijp
  real,    allocatable, dimension(:,:) :: kreactions_z
  real,    allocatable, dimension(:)   :: kreactions_m,kreactions_p
  character (len=30),allocatable, dimension(:) :: reaction_name

   real :: Rgas, Rgas_unit_sys=1.

!
!  hydro-related parameters
!
  real, dimension(nchemspec) :: amplchemk=0.,amplchemk2=0.
  real, dimension(nchemspec) :: chem_diff_prefactor=1.
  real :: amplchem=1.,kx_chem=1.,ky_chem=1.,kz_chem=1.,widthchem=1.
  real :: chem_diff=0.
  character (len=labellen), dimension (ninit) :: initchem='nothing'
  character (len=labellen), dimension (2*nchemspec) :: kreactions_profile=''

!
!  Chemkin related parameters
!
  logical :: lcheminp=.false.
  real, dimension(nchemspec,18) :: species_constants
  integer :: imass=1, iTemp1=2,iTemp2=3,iTemp3=4
  integer, dimension(7) :: ia1,ia2
  real,    allocatable, dimension(:) :: B_n, alpha_n, E_an

! input parameters
  namelist /chemistry_init_pars/ &
      initchem, amplchem, kx_chem, ky_chem, kz_chem, widthchem, &
      amplchemk,amplchemk2

! run parameters
  namelist /chemistry_run_pars/ &
      lkreactions_profile,kreactions_profile,kreactions_profile_width, &
      chem_diff,chem_diff_prefactor
!
! diagnostic variables (need to be consistent with reset list below)
!
  integer :: idiag_Y1m=0        ! DIAG_DOC: $\left<Y_1\right>$
  integer :: idiag_Y2m=0        ! DIAG_DOC: $\left<Y_2\right>$
  integer :: idiag_Y3m=0        ! DIAG_DOC: $\left<Y_3\right>$
  integer :: idiag_Y4m=0        ! DIAG_DOC: $\left<Y_4\right>$
  integer :: idiag_Y5m=0        ! DIAG_DOC: $\left<Y_5\right>$
  integer :: idiag_Y6m=0        ! DIAG_DOC: $\left<Y_6\right>$
  integer :: idiag_Y7m=0        ! DIAG_DOC: $\left<Y_7\right>$
  integer :: idiag_Y8m=0        ! DIAG_DOC: $\left<Y_8\right>$
!
  contains

!***********************************************************************
    subroutine register_chemistry()
!
!  Configure pre-initialised (i.e. before parameter read) variables
!  which should be know to be able to evaluate
!
!  13-aug-07/steveb: coded
!   8-jan-08/axel: added modifications analogously to dustdensity
!   5-mar-08/nils: Read thermodynamical data from chem.inp
!
      use Cdata
      use Mpicomm
      use General, only: chn
!
      logical, save :: first=.true.
      integer :: k
      character (len=5) :: schem
      character (len=20) :: input_file='chem.inp'
!
! Initialize some index pointers
!
      ia1(1)=5;ia1(2)=6;ia1(3)=7;ia1(4)=8;ia1(5)=9;ia1(6)=10;ia1(7)=11
      ia2(1)=12;ia2(2)=13;ia2(3)=14;ia2(4)=15;ia2(5)=16;ia2(6)=17;ia2(7)=18
!
! A quick sanity check
!
      if (.not. first) call stop_it('register_chemistry called twice')
      first=.false.
!
!  Set ind to consecutive numbers nvar+1, nvar+2, ..., nvar+nchemspec
!

      do k=1,nchemspec
        ichemspec(k)=nvar+k
      enddo
!
!  Increase nvar accordingly
!
      nvar=nvar+nchemspec
!
!  Read species to be used from chem.inp (if the file exists)
!     
      inquire(FILE=input_file, EXIST=lcheminp)
      if (lcheminp) then
        call read_species(input_file)
      else
        do k=1,nchemspec
          !
          !  Put variable name in array
          !
          call chn(k,schem)
          varname(ichemspec(k))='nd('//trim(schem)//')'
        enddo
      endif
!
!  Print some diagnostics
!
      do k=1,nchemspec
        write(*,'("register_chemistry: k=",I4," nvar=",I4," ichemspec(k)=",I4," name=",8A)') &
          k, nvar, ichemspec(k), trim(varname(ichemspec(k)))
      enddo
!
!  Read data on the thermodynamical properties of the different species.
!  All these data are stored in the array species_constants.
!
      if (lcheminp) call read_thermodyn(input_file)
!
!  Write all data on species and their thermodynamics to file 
!
      if (lcheminp) call write_thermodyn()
!
!  identify CVS version information (if checked in to a CVS repository!)
!  CVS should automatically update everything between $Id: chemistry.f90,v 1.28 2008-03-17 14:35:14 nbabkovs Exp $
!  when the file in committed to a CVS repository.
!
      if (lroot) call cvs_id( &
           "$Id: chemistry.f90,v 1.28 2008-03-17 14:35:14 nbabkovs Exp $")
!
!
!  Perform some sanity checks (may be meaningless if certain things haven't
!  been configured in a custom module but they do no harm)
!
      if (naux > maux) then
        if (lroot) write(0,*) 'naux = ', naux, ', maux = ', maux
        call stop_it('register_chemistry: naux > maux')
      endif
!
      if (nvar > mvar) then
        if (lroot) write(0,*) 'nvar = ', nvar, ', mvar = ', mvar
        call stop_it('register_chemistry: nvar > mvar')
      endif
!
    endsubroutine register_chemistry
!***********************************************************************
    subroutine initialize_chemistry(f)
!
!  called by run.f90 after reading parameters, but before the time loop
!
!  13-aug-07/steveb: coded
!  19-feb-08/axel: reads in chemistry.dat file
!
      use Cdata
      use Mpicomm, only: stop_it
      use Sub, only: keep_compiler_quiet
      use General, only: chn
!
      character (len=80) :: chemicals=''
      character (len=15) :: file1='chemistry_m.dat',file2='chemistry_p.dat'
      character (len=20) :: input_file='chem.inp'
      real, dimension (mx,my,mz,mfarray) :: f
      logical :: exist,exist1,exist2
      integer :: i,j,k,stat,reac,spec
!
!  Find number of ractions
!
      if (lcheminp) then
        call read_reactions(input_file,NrOfReactions=mreactions)
        print*,'Number of reactions=',mreactions
      else
        mreactions=2*nchemspec
      endif
!
!  Allocate reaction arrays
!
      allocate(stoichio(nchemspec,mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for stoichio")
      allocate(Sijm(nchemspec,mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for Sijm")
      allocate(Sijp(nchemspec,mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for Sijp")
      allocate(kreactions_z(mz,mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for kreactions_z")
      allocate(kreactions_p(mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for kreactions_p")
      allocate(kreactions_m(mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for kreactions_m")
      allocate(reaction_name(mreactions),STAT=stat)
      if (stat>0) call stop_it("Couldn't allocate memory for reaction_name")
      if (lcheminp) then
        allocate(B_n(mreactions),STAT=stat)
        if (stat>0) call stop_it("Couldn't allocate memory for B_n")
        allocate(alpha_n(mreactions),STAT=stat)
        if (stat>0) call stop_it("Couldn't allocate memory for alpha_n")
        allocate(E_an(mreactions),STAT=stat)
        if (stat>0) call stop_it("Couldn't allocate memory for E_an")
      end if
!
!  Initialize data
!
      kreactions_z=1.
      Sijp=0
      Sijm=0
!
!  read chemistry data
!
      inquire(file=file1,exist=exist1)
      inquire(file=file2,exist=exist2)
! 
      if (lcheminp) then
        call read_reactions(input_file)
        call write_reactions()
      elseif(exist1.and.exist2) then
!
!  if both chemistry1.dat and chemistry2.dat are present,
!  then read Sijp and Sijm, and calculate their sum
!
!  file1
!
        open(19,file=file1)
        read(19,*) chemicals
        do j=1,mreactions
          read(19,*,end=994) kreactions_m(j),(Sijm(i,j),i=1,nchemspec)
        enddo
994     close(19)
        nreactions1=j-1
!
!  file2
!
        open(19,file=file2)
        read(19,*) chemicals
        do j=1,mreactions
          read(19,*,end=992) kreactions_p(j),(Sijp(i,j),i=1,nchemspec)
        enddo
992     close(19)
        nreactions2=j-1
!
!  calculate stoichio and nreactions
!
        if (nreactions1==nreactions2) then
          nreactions=nreactions1
          stoichio=Sijp-Sijm
        else
          call stop_it('nreactions1/=nreactions2')
        endif
!
      else 
!
!  old method: read chemistry data, if present
!
        inquire(file='chemistry.dat',exist=exist)
        if(exist) then
          open(19,file='chemistry.dat')
          read(19,*) chemicals
          do j=1,mreactions
            read(19,*,end=990) kreactions_p(j),(stoichio(i,j),i=1,nchemspec)
          enddo
990       close(19)
          nreactions=j-1
          Sijm=-min(stoichio,0)
          Sijp=+max(stoichio,0)
        else
          if (lroot) print*,'no chemistry.dat file to be read.'
          lreactions=.false.
        endif
      endif
!
!  print input data for verification
!
      if (lroot) then
        print*,'chemicals=',chemicals
        print*,'kreactions_m=',kreactions_m(1:nreactions)
        print*,'kreactions_p=',kreactions_p(1:nreactions)
        print*,'Sijm:' ; write(*,100),Sijm(:,1:nreactions)
        print*,'Sijp:' ; write(*,100),Sijp(:,1:nreactions)
        print*,'stoichio=' ; write(*,100),stoichio(:,1:nreactions)
      endif
!
!  possibility of z-dependent kreactions_z profile
!
      if (lkreactions_profile) then
        do j=1,nreactions
          if (kreactions_profile(j)=='cosh') then
            do n=1,mz
              kreactions_z(n,j)=1./cosh(z(n)/kreactions_profile_width(j))**2
            enddo
          endif
        enddo
      endif
!
!  that's it
!
      call keep_compiler_quiet(f)
!
100   format(8i4)
    endsubroutine initialize_chemistry
!***********************************************************************
    subroutine init_chemistry(f,xx,yy,zz)
!
!  initialise chemistry initial condition; called from start.f90
!  13-aug-07/steveb: coded
!
      use Cdata
      use Initcond
      use Mpicomm
      use Sub
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz) :: xx,yy,zz
      integer :: j,k
      logical :: lnothing
!
      intent(in) :: xx,yy,zz
      intent(inout) :: f
!
!  different initializations of nd (called from start)
!
      lnothing=.false.
      do j=1,ninit
        select case(initchem(j))

        case('nothing')
          if (lroot .and. .not. lnothing) print*, 'init_chem: nothing'
          lnothing=.true.
        case('constant')
          do k=1,nchemspec
            f(:,:,:,ichemspec(k))=amplchemk(k)
          enddo
        case('positive-noise')
          do k=1,nchemspec
            call posnoise(amplchemk(k),f,ichemspec(k))
          enddo
        case('innerbox')
          do k=1,nchemspec
            call innerbox(amplchemk(k),amplchemk2(k),f,ichemspec(k),widthchem)
          enddo
        case('cos2x_cos2y_cos2z')
          do k=1,nchemspec
            call cos2x_cos2y_cos2z(amplchemk(k),f,ichemspec(k))
          enddo
        case('coswave-x')
          do k=1,nchemspec
            call coswave(amplchem,f,ichemspec(k),kx=kx_chem)
          enddo
        case('hatwave-x')
          do k=1,nchemspec
            call hatwave(amplchem,f,ichemspec(k),kx=kx_chem)
          enddo
        case('hatwave-y')
          do k=1,nchemspec
            call hatwave(amplchem,f,ichemspec(k),ky=ky_chem)
          enddo
        case('hatwave-z')
          do k=1,nchemspec
            call hatwave(amplchem,f,ichemspec(k),kz=kz_chem)
          enddo
        case default
!
!  Catch unknown values
!
          if (lroot) print*, 'initchem: No such value for initchem: ', &
              trim(initchem(j))
          call stop_it('')

        endselect
      enddo
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(xx,yy,zz)
!
    endsubroutine init_chemistry
!***********************************************************************
    subroutine pencil_criteria_chemistry()
!
!  All pencils that this chemistry module depends on are specified here.
!
!  13-aug-07/steveb: coded
!
    endsubroutine pencil_criteria_chemistry
!***********************************************************************
    subroutine pencil_interdep_chemistry(lpencil_in)
!
!  Interdependency among pencils provided by this module are specified here
!
!  13-aug-07/steveb: coded
!
      use Sub, only: keep_compiler_quiet
!
      logical, dimension(npencils) :: lpencil_in
!
      call keep_compiler_quiet(lpencil_in)
!
    endsubroutine pencil_interdep_chemistry
!***********************************************************************
    subroutine calc_pencils_chemistry(f,p)
!
!  Calculate Hydro pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!   13-aug-07/steveb: coded
!
      use Cdata
      use Sub
      use Cparam
      use EquationOfState
      use Mpicomm, only: stop_it
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (pencil_case) :: p
      real, dimension (nx) :: mu1_cgs, cp_spec
      real, dimension (mx,my,mz) :: cp_full
!
      intent(in) :: f
      intent(inout) :: p
      integer :: k,i,j
      real :: T_local, T_up, T_mid, T_low, tmp,  lnT_local
      logical :: lcheminp_tmp=.false.


 if (lcheminp) then
  if (unit_system == 'cgs') then

     Rgas_unit_sys = k_B_cgs/m_u_cgs
    Rgas=Rgas_unit_sys*unit_temperature/unit_velocity**2
!
!  Mean molecular weight
!
       mu1_cgs=0.
        if (lpencil(i_mu1)) then 
          do k=1,nchemspec
           mu1_cgs=mu1_cgs+f(l1:l2,m,n,ichemspec(k))/species_constants(ichemspec(k),imass)
          enddo
          p%mu1=mu1_cgs*unit_mass
        endif
!
!  Pressure
!
       if (lpencil(i_pp)) p%pp = Rgas*p%mu1*p%rho*p%TT
!
!  Specific heat at constant pressure
!
       cp_full(:,m,n)=0.

      if (lpencil(i_cp)) then
        do k=1,nchemspec
          T_low=species_constants(k,iTemp1)
          T_mid=species_constants(k,iTemp2)
          T_up= species_constants(k,iTemp3)
         do i=1,nx
          T_local=p%TT(i)*unit_temperature 
           if (T_local >=T_low .and. T_local <= T_mid) then
               tmp=0. 
               do j=1,5
                tmp=tmp+species_constants(k,ia1(j))*T_local**(j-1) 
               enddo
               cp_spec(i)=tmp
           else
               tmp=0. 
               do j=1,5 
                tmp=tmp+species_constants(k,ia2(j))*T_local**(j-1) 
               enddo
               cp_spec(i)=tmp
           endif
          cp_full(l1:l2,m,n)=cp_full(l1:l2,m,n)+f(l1:l2,m,n,ichemspec(k))*cp_spec(:)*Rgas*p%mu1
         enddo
        enddo
        p%cp=cp_full(l1:l2,m,n)
     endif

      if (lpencil(i_cp1))   p%cp1 = 1./p%cp

!  Gradient of the above
!
      if (lpencil(i_gradcp)) call grad(cp_full,p%gradcp)
!
!  Specific heat at constant volume (i.e. density)
!
     if (lpencil(i_cv)) p%cv = p%cp - Rgas

!print*, p%cp(10), p%cv(10), Rgas

      if (lpencil(i_cv1)) p%cv1=1/p%cv
      if (lpencil(i_lncp)) p%lncp=log(p%cp)

!
!  Polytropic index
!
      if (lpencil(i_gamma)) p%gamma = p%cp*p%cv1
      if (lpencil(i_gamma11)) p%gamma11 = p%cv*p%cp1
      if (lpencil(i_gamma1)) p%gamma1 = p%gamma - 1

!
!  Dimensionless Standard-state molar enthalpy H0/RT
!

       if (lpencil(i_H0RT)) then
        do k=1,nchemspec
          T_low=species_constants(k,iTemp1)
          T_mid=species_constants(k,iTemp2)
          T_up= species_constants(k,iTemp3)
         do i=1,nx
          T_local=p%TT(i)*unit_temperature 
           if (T_local >=T_low .and. T_local <= T_mid) then
               tmp=0. 
               do j=1,5
                tmp=tmp+species_constants(k,ia1(j))*T_local**(j-1)/j 
               enddo
              p%H0RT(:,k)=tmp+species_constants(k,ia1(6))/T_local
           else
               tmp=0. 
               do j=1,5 
                tmp=tmp+species_constants(k,ia2(j))*T_local**(j-1)/j 
               enddo
             p%H0RT(:,k)=tmp+species_constants(k,ia2(6))/T_local
           endif
         enddo
        enddo
       endif 
!

!
!  Dimensionless Standard-state molar entropy  S0/R
!

       if (lpencil(i_S0R)) then
        do k=1,nchemspec
          T_low=species_constants(k,iTemp1)
          T_mid=species_constants(k,iTemp2)
          T_up= species_constants(k,iTemp3)
         do i=1,nx
          T_local=p%TT(i)*unit_temperature 
          lnT_local=p%lnTT(i)+log(unit_temperature)
           if (T_local >=T_low .and. T_local <= T_mid) then
               tmp=0. 
               do j=2,5
                tmp=tmp+species_constants(k,ia1(j))*T_local**(j-1)/(j-1) 
               enddo
              p%S0R(:,k)=species_constants(k,ia1(1))*lnT_local+tmp+species_constants(k,ia1(7))
           else
               tmp=0. 
               do j=2,5 
                tmp=tmp+species_constants(k,ia2(j))*T_local**(j-1)/(j-1) 
               enddo
             p%S0R(:,k)=species_constants(k,ia2(1))*lnT_local+tmp+species_constants(k,ia2(7))
           endif
         enddo
        enddo
       endif 
!


   else
    call stop_it('This case works only for cgs units system!')
   endif

  endif



      call keep_compiler_quiet(f)
      call keep_compiler_quiet(p)
!
    endsubroutine calc_pencils_chemistry
!***********************************************************************
    subroutine dchemistry_dt(f,df,p)
!
!  calculate right hand side of ONE OR MORE extra coupled PDEs
!  along the 'current' Pencil, i.e. f(l1:l2,m,n) where
!  m,n are global variables looped over in equ.f90
!
!  Due to the multi-step Runge Kutta timestepping used one MUST always
!  add to the present contents of the df array.  NEVER reset it to zero.
!
!  several precalculated Pencils of information are passed if for
!  efficiency.
!
!   13-aug-07/steveb: coded
!    8-jan-08/natalia: included advection/diffusion
!   20-feb-08/axel: included reactions
!
      use Cdata
      use Mpicomm
      use Sub
      use Global
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
     
      real, dimension (nx,3) :: gchemspec
      real, dimension (nx) :: ugchemspec,del2chemspec,diff_op,xdot
      real, dimension (nx,mreactions) :: vreactions,vreactions_p,vreactions_m
      real :: diff_k
      type (pencil_case) :: p
!
!  indices
!
      integer :: j,k
      integer :: i1=1,i2=2,i3=3,i4=4,i5=5,i6=6,i7=7,i8=8
!
      intent(in) :: f,p
      intent(inout) :: df
!
!  identify module and boundary conditions
!
      if (headtt.or.ldebug) print*,'dchemistry_dt: SOLVE dchemistry_dt'
!!      if (headtt) call identify_bcs('ss',iss)
!
!  if we do reactions, we must calculate the reaction speed vector
!  outside the loop where we multiply it by the stoichiometric matrix
!
      if (lreactions) then

       if (.not. lcheminp) then
! Axel' case
        do j=1,nreactions
          vreactions_p(:,j)=kreactions_p(j)*kreactions_z(n,j)
          vreactions_m(:,j)=kreactions_m(j)*kreactions_z(n,j)
          do k=1,nchemspec
            vreactions_p(:,j)=vreactions_p(:,j)*f(l1:l2,m,n,ichemspec(k))**Sijm(k,j)
            vreactions_m(:,j)=vreactions_m(:,j)*f(l1:l2,m,n,ichemspec(k))**Sijp(k,j)
          enddo
        enddo
       else
! Chemkin data case
         call get_reaction_rate(f,vreactions_p,vreactions_m)
       endif 

        vreactions=vreactions_p-vreactions_m

      endif
!
!  loop over all chemicals
!
      diff_k=chem_diff
      do k=1,nchemspec
!
!  advection terms
!
        call grad(f,ichemspec(k),gchemspec) 
        call dot_mn(p%uu,gchemspec,ugchemspec)
        df(l1:l2,m,n,ichemspec(k))=df(l1:l2,m,n,ichemspec(k))-ugchemspec
!
!  diffusion operator
!
        if (chem_diff/=0.) then
          diff_k=chem_diff*chem_diff_prefactor(k)
          if (headtt) print*,'dchemistry_dt: k,diff_k=',k,diff_k
          call del2(f,ichemspec(k),del2chemspec) 
          call dot_mn(p%glnrho,gchemspec,diff_op)
          diff_op=diff_op+del2chemspec
          df(l1:l2,m,n,ichemspec(k))=df(l1:l2,m,n,ichemspec(k))+diff_k*diff_op
        endif
!
!  chemical reactions:
!  multiply with stoichiometric matrix with reaction speed
!  d/dt(x_i) = S_ij v_j
!
        if (lreactions) then
          xdot=0.
          do j=1,nreactions
            xdot=xdot+stoichio(k,j)*vreactions(:,j)
          enddo
          df(l1:l2,m,n,ichemspec(k))=df(l1:l2,m,n,ichemspec(k))+xdot
        endif
!
      enddo 
!
!  For the timestep calculation, need maximum diffusion
!
        if (lfirst.and.ldt) then
          diffus_chem=chem_diff*maxval(chem_diff_prefactor)*dxyz_2
        endif
!
!  Calculate diagnostic quantities
!
      if (ldiagnos) then
        if (idiag_Y1m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i1)),idiag_Y1m)
        if (idiag_Y2m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i2)),idiag_Y2m)
        if (idiag_Y3m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i3)),idiag_Y3m)
        if (idiag_Y4m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i4)),idiag_Y4m)
        if (idiag_Y5m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i5)),idiag_Y5m)
        if (idiag_Y6m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i6)),idiag_Y6m)
        if (idiag_Y7m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i7)),idiag_Y7m)
        if (idiag_Y8m/=0) call sum_mn_name(f(l1:l2,m,n,ichemspec(i8)),idiag_Y8m)
      endif
!
! Keep compiler quiet by ensuring every parameter is used
!
      call keep_compiler_quiet(f,df)
      call keep_compiler_quiet(p)

    endsubroutine dchemistry_dt
!***********************************************************************
    subroutine read_chemistry_init_pars(unit,iostat)
!
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
!
      if (present(iostat)) then
        read(unit,NML=chemistry_init_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=chemistry_init_pars,ERR=99)
      endif
!
99    return
    endsubroutine read_chemistry_init_pars
!***********************************************************************
    subroutine write_chemistry_init_pars(unit)
!
      integer, intent(in) :: unit

      write(unit,NML=chemistry_init_pars)

    endsubroutine write_chemistry_init_pars
!***********************************************************************
    subroutine read_chemistry_run_pars(unit,iostat)
!
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
!
      if (present(iostat)) then
        read(unit,NML=chemistry_run_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=chemistry_run_pars,ERR=99)
      endif
!
99    return
    endsubroutine read_chemistry_run_pars
!***********************************************************************
    subroutine write_chemistry_run_pars(unit)
!
      integer, intent(in) :: unit

      write(unit,NML=chemistry_run_pars)

    endsubroutine write_chemistry_run_pars
!***********************************************************************
    subroutine rprint_chemistry(lreset,lwrite)
!
!  reads and registers print parameters relevant to chemistry
!
!  13-aug-07/steveb: coded
!
      use Cdata
      use Sub
      use General, only: chn
!
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
      character (len=5) :: schem,schemspec,snd1,smd1,smi1
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
!  reset everything in case of reset
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        idiag_Y1m=0; idiag_Y2m=0; idiag_Y3m=0; idiag_Y4m=0
        idiag_Y5m=0; idiag_Y6m=0; idiag_Y7m=0; idiag_Y8m=0
      endif
!
      call chn(nchemspec,schemspec)
!
!  check for those quantities that we want to evaluate online
!
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'Y1m',idiag_Y1m)
        call parse_name(iname,cname(iname),cform(iname),'Y2m',idiag_Y2m)
        call parse_name(iname,cname(iname),cform(iname),'Y3m',idiag_Y3m)
        call parse_name(iname,cname(iname),cform(iname),'Y4m',idiag_Y4m)
        call parse_name(iname,cname(iname),cform(iname),'Y5m',idiag_Y5m)
        call parse_name(iname,cname(iname),cform(iname),'Y6m',idiag_Y6m)
        call parse_name(iname,cname(iname),cform(iname),'Y7m',idiag_Y7m)
        call parse_name(iname,cname(iname),cform(iname),'Y8m',idiag_Y8m)
      enddo
!
!  Write chemistry index in short notation
!
      call chn(ichemspec(1),snd1)
      if (lwr) then
        write(3,*) 'i_Y1m=',idiag_Y1m
        write(3,*) 'i_Y2m=',idiag_Y2m
        write(3,*) 'i_Y3m=',idiag_Y3m
        write(3,*) 'i_Y4m=',idiag_Y4m
        write(3,*) 'i_Y5m=',idiag_Y5m
        write(3,*) 'i_Y6m=',idiag_Y6m
        write(3,*) 'i_Y7m=',idiag_Y7m
        write(3,*) 'i_Y8m=',idiag_Y8m
        write(3,*) 'ichemspec=indgen('//trim(schemspec)//') + '//trim(snd1)
      endif
!
    endsubroutine rprint_chemistry
!***********************************************************************
    subroutine get_slices_chemistry(f,slices)
!
!  Write slices for animation of chemistry variables.
!
!  13-aug-07/steveb: dummy
!
      use Sub, only: keep_compiler_quiet
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (slice_data) :: slices
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(slices%ready)
!
    endsubroutine get_slices_chemistry
!***********************************************************************
    subroutine special_calc_density(f,df,p)
!
!   calculate a additional 'special' term on the right hand side of the
!   entropy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   13-aug-07/steveb: coded
!
      use Cdata
      use Sub, only: keep_compiler_quiet
!
      real, dimension (mx,my,mz,mfarray), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p

!!
!!  SAMPLE IMPLEMENTATION
!!     (remember one must ALWAYS add to df)
!!
!!
!!  df(l1:l2,m,n,ilnrho) = df(l1:l2,m,n,ilnrho) + SOME NEW TERM
!!
!!
      call keep_compiler_quiet(f,df)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_density
!***********************************************************************
    subroutine special_calc_hydro(f,df,p)
!
!   calculate a additional 'special' term on the right hand side of the
!   entropy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   13-aug-07/steveb: coded
!
      use Cdata
      use Sub, only: keep_compiler_quiet

      real, dimension (mx,my,mz,mfarray), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p

!!
!!  SAMPLE IMPLEMENTATION
!!     (remember one must ALWAYS add to df)
!!
!!
!!  df(l1:l2,m,n,iux) = df(l1:l2,m,n,iux) + SOME NEW TERM
!!  df(l1:l2,m,n,iuy) = df(l1:l2,m,n,iuy) + SOME NEW TERM
!!  df(l1:l2,m,n,iuz) = df(l1:l2,m,n,iuz) + SOME NEW TERM
!!
!!
      call keep_compiler_quiet(f,df)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_hydro
!***********************************************************************
    subroutine special_calc_magnetic(f,df,p)
!
!   calculate a additional 'special' term on the right hand side of the
!   entropy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   13-aug-07/steveb: coded
!
      use Cdata
      use Sub, only: keep_compiler_quiet

      real, dimension (mx,my,mz,mfarray), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p

!!
!!  SAMPLE IMPLEMENTATION
!!     (remember one must ALWAYS add to df)
!!
!!
!!  df(l1:l2,m,n,iux) = df(l1:l2,m,n,iux) + SOME NEW TERM
!!  df(l1:l2,m,n,iuy) = df(l1:l2,m,n,iuy) + SOME NEW TERM
!!  df(l1:l2,m,n,iuz) = df(l1:l2,m,n,iuz) + SOME NEW TERM
!!
      call keep_compiler_quiet(f,df)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_magnetic
!!***********************************************************************
    subroutine special_calc_entropy(f,df,p)
!
!   calculate a additional 'special' term on the right hand side of the
!   entropy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   13-aug-07/steveb: coded
!
      use Cdata
      use Sub, only: keep_compiler_quiet

      real, dimension (mx,my,mz,mfarray), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p

!!
!!  SAMPLE IMPLEMENTATION
!!     (remember one must ALWAYS add to df)
!!
!!
!!  df(l1:l2,m,n,ient) = df(l1:l2,m,n,ient) + SOME NEW TERM
!!
!!
      call keep_compiler_quiet(f,df)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_entropy
!***********************************************************************
    subroutine special_before_boundary(f)
!
!   Possibility to modify the f array before the boundaries are
!   communicated.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-jul-06/tony: coded
!
      use Cdata
      use Sub, only: keep_compiler_quiet
!
      real, dimension (mx,my,mz,mfarray), intent(in) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine special_before_boundary
!***********************************************************************
    subroutine find_species_index(species_name,ind_glob,ind_chem,found_specie)
!
!   Find index in the f array for specie
!
!   2008-02-05/Nils Erland: coded
!
      use Cdata
!
      integer, intent(out) :: ind_glob,ind_chem
      character (len=*), intent(in) :: species_name
      integer :: k
      logical, intent(out) :: found_specie
!
      ind_glob=0
      do k=1,nchemspec
        if (trim(varname(ichemspec(k)))==species_name) then
          ind_glob=k+ichemspec(1)-1
          ind_chem=k
          exit
        endif
      enddo
      !
      ! Check if the specie was really found
      !
      if (ind_glob==0) then
        found_specie=.false. 
print*,species_name
      else
        found_specie=.true.
      endif
!
    endsubroutine find_species_index
!***********************************************************************
    subroutine find_mass(element_name,MolMass)
      !
      ! Find mass of element
      !
      ! 2008-02-05/Nils Erland: coded
      !
      use Mpicomm
      !
      character (len=*), intent(in) :: element_name
      real, intent(out) :: MolMass
      !
      select case (element_name)
      case('H')  
        MolMass=1.00794
      case('C')  
        MolMass=12.0107
      case('N')  
        MolMass=14.00674
      case('O')  
        MolMass=15.9994
      case('Ar','AR') 
        MolMass=39.948
      case('He','HE') 
        MolMass=4.0026
      case default
        print*,'element_name=',element_name
        call stop_it('find_mass: Element not found!')
      end select
      !
    end subroutine find_mass
!***********************************************************************
     subroutine read_species(input_file)
      !
      ! This subroutine reads all species information from chem.inp
      ! See the chemkin manual for more information on
      ! the syntax of chem.inp.
      !
      ! 2008.03.06 Nils Erland: Coded
      !
      use Mpicomm
      !
      logical :: IsSpecie=.false., emptyfile
      integer :: k,file_id=123, StartInd, StopInd
      character (len=80) :: ChemInpLine
      character (len=*) :: input_file
      !
      emptyFile=.true.
      k=1
      open(file_id,file=input_file)
      dataloop: do
        read(file_id,'(80A)',end=1000) ChemInpLine(1:80)
        emptyFile=.false.
        !
        ! Check if we are reading a line within the species section
        !
        if (ChemInpLine(1:7)=="SPECIES")            IsSpecie=.true.
        if (ChemInpLine(1:3)=="END" .and. IsSpecie) IsSpecie=.false.
        !
        ! Read in species
        !
        if (IsSpecie) then
          if (ChemInpLine(1:7) /= "SPECIES") then
            StartInd=1; StopInd =0
            stringloop: do
              StopInd=index(ChemInpLine(StartInd:),' ')+StartInd-1
              if (StopInd==StartInd) then
                StartInd=StartInd+1
              else
                varname(ichemspec(k))=trim(ChemInpLine(StartInd:StopInd-1))
                StartInd=StopInd
                k=k+1
                if (k>nvar) then
                  print*,'nchemspec=',nchemspec
                  call stop_it("There were too many species, please increase nchemspec!")
                endif
              endif
              if (StartInd==80) exit
            enddo stringloop
          endif
        endif
      enddo dataloop
      !
      ! Stop if chem.inp is empty
      !
1000  if (emptyFile)  call stop_it('The input file chem.inp was empty!')
      close(file_id)
      !
    end subroutine read_species
 !********************************************************************
    subroutine read_thermodyn(input_file)
      !
      ! This subroutine reads the thermodynamical data for all species 
      ! from chem.inp. See the chemkin manual for more information on
      ! the syntax of chem.inp.
      !
      ! 2008.03.06 Nils Erland: Coded
      !
      character (len=*), intent(in) :: input_file
      integer :: file_id=123, ind_glob, ind_chem
      character (len=80) :: ChemInpLine
      integer :: In1,In2,In3,In4,In5,iElement,iTemperature,nn2,StopInd
      integer :: NumberOfElement_i
      logical :: IsThermo=.false., found_specie
      real, dimension(4) :: MolMass
      real, dimension(3) :: tmp_temp
      character (len=5) :: NumberOfElement_string,element_string
      character (len=10) :: specie_string,TemperatureNr_i
      real :: nne
      !
      open(file_id,file=input_file)
      dataloop2: do
        read(file_id,'(80A)',end=1001) ChemInpLine(1:80)
        !
        ! Check if we are reading a line within the thermo section
        !
        if (ChemInpLine(1:6)=="THERMO") IsThermo=.true.
        if (ChemInpLine(1:3)=="END" .and. IsThermo) IsThermo=.false.
        !
        ! Read in thermo data
        !
        if (IsThermo) then
          if (ChemInpLine(1:7) /= "THERMO") then
            StopInd=index(ChemInpLine,' ')
            specie_string=trim(ChemInpLine(1:StopInd-1))
            call find_species_index(specie_string,ind_glob,ind_chem,found_specie)
            if (found_specie) then
              !
              ! Find molar mass
              !
              MolMass=0
              do iElement=1,4                
                In1=25+(iElement-1)*5
                In2=26+(iElement-1)*5
                In3=27+(iElement-1)*5
                In4=29+(iElement-1)*5
                if (ChemInpLine(In1:In1)==' ') then
                  MolMass(iElement)=0
                else
                  element_string=trim(ChemInpLine(In1:In2))
                  call find_mass(element_string,MolMass(iElement))
                  In5=verify(ChemInpLine(In3:In4),' ')+In3-1
                  NumberOfElement_string=trim(ChemInpLine(In5:In4))
                  read (unit=NumberOfElement_string,fmt='(I5)') NumberOfElement_i
                  MolMass(iElement)=MolMass(iElement)*NumberOfElement_i
                endif
              enddo
              species_constants(ind_chem,imass)=sum(MolMass)
              !
              ! Find temperature-ranges for low and high temperature fitting
              !
              do iTemperature=1,3
                In1=46+(iTemperature-1)*10
                In2=55+(iTemperature-1)*10
                if (iTemperature==3) In2=73
                In3=verify(ChemInpLine(In1:In2),' ')+In1-1
                TemperatureNr_i=trim(ChemInpLine(In3:In2))
                read (unit=TemperatureNr_i,fmt='(F10.1)') nne
                tmp_temp(iTemperature)=nne
              enddo
              species_constants(ind_chem,iTemp1)=tmp_temp(1)
              species_constants(ind_chem,iTemp2)=tmp_temp(3)
              species_constants(ind_chem,iTemp3)=tmp_temp(2)
            elseif (ChemInpLine(80:80)=="2") then
              ! Read ia1(1):ia1(5)
              read (unit=ChemInpLine(1:75),fmt='(5E15.8)')  &
                   species_constants(ind_chem,ia1(1):ia1(5))
           elseif (ChemInpLine(80:80)=="3") then
              ! Read ia1(6):ia5(3)
              read (unit=ChemInpLine(1:75),fmt='(5E15.8)')  &
                   species_constants(ind_chem,ia1(6):ia2(3))
            elseif (ChemInpLine(80:80)=="4") then
              ! Read ia2(4):ia2(7)
              read (unit=ChemInpLine(1:75),fmt='(4E15.8)')  &
                   species_constants(ind_chem,ia2(4):ia2(7))
            endif
          endif
        endif
      enddo dataloop2
1001  continue
      close(file_id)
      !
    end subroutine read_thermodyn
!***********************************************************************
     subroutine read_reactions(input_file,NrOfReactions)
      !
      ! This subroutine reads all reaction information from chem.inp
      ! See the chemkin manual for more information on
      ! the syntax of chem.inp.
      !
      ! 2008.03.10 Nils Erland: Coded
      !
      use Mpicomm
      !
      logical :: IsReaction=.false.,LastSpecie
      integer, optional :: NrOfReactions
      integer :: k,file_id=123, StartInd, StopInd, StopIndName
      integer :: VarNumber, SeparatorInd, StartSpecie,stoi, PlusInd
      integer :: LastLeftCharacter,ParanthesisInd
      character (len=80) :: ChemInpLine
      character (len=*) :: input_file
      !

      if (present(NrOfReactions)) NrOfReactions=0

      k=1
      open(file_id,file=input_file)
      dataloop3: do
        read(file_id,'(80A)',end=1012) ChemInpLine(1:80)
        !
        ! Check if we are reading a line within the reactions section
        !
        if (ChemInpLine(1:9)=="REACTIONS")            IsReaction=.true.
        if (ChemInpLine(1:3)=="END" .and. IsReaction) IsReaction=.false.
        !
        if (present(NrOfReactions)) then
          !
          ! Find number of reactions
          !
          if (IsReaction) then
            if (ChemInpLine(1:9) /= "REACTIONS") then
              StartInd=1; StopInd =0
              StopInd=index(ChemInpLine(StartInd:),'=')+StartInd-1
              if (StopInd>0 .and. ChemInpLine(1:1) /= '!') then
                NrOfReactions=NrOfReactions+1
              endif
            endif
          endif
        else
          !
          ! Read in species
          !
          if (IsReaction) then
            if (ChemInpLine(1:9) /= "REACTIONS") then
              StartInd=1; StopInd =0
              StopInd=index(ChemInpLine(StartInd:),'=')+StartInd-1
              if (StopInd>0 .and. ChemInpLine(1:1) /= '!') then
                !
                ! Fill in reaction name
                !
!                print*,'Find reaction name.'
                StopIndName=index(ChemInpLine(StartInd:),' ')+StartInd-1
                reaction_name(k)=ChemInpLine(StartInd:StopIndName)
                !
                ! Find reactant side stoichiometric coefficients
                !
                SeparatorInd=index(ChemInpLine(StartInd:),'<=')
                if (SeparatorInd==0) then
                  SeparatorInd=index(ChemInpLine(StartInd:),'=')
                endif
                !
                ParanthesisInd=index(ChemInpLine(StartInd:),'(+M)')
                if (ParanthesisInd>0) then
                  LastLeftCharacter=min(ParanthesisInd,SeparatorInd)-1
                else
                  LastLeftCharacter=SeparatorInd-1
                endif
                !
                StartInd=1
                PlusInd=index(ChemInpLine(StartInd:LastLeftCharacter),'+')&
                     +StartInd-1
                do while (PlusInd<LastLeftCharacter .AND. PlusInd>0)
                  StopInd=PlusInd-1
                  call build_stoich_matrix(StartInd,StopInd,k,ChemInpLine,.false.)
                  StartInd=StopInd+2
                  PlusInd=index(ChemInpLine(StartInd:),'+')+StartInd-1
                enddo
                StopInd=LastLeftCharacter
                call build_stoich_matrix(StartInd,StopInd,k,ChemInpLine,.false.)
                !
                ! Find product side stoichiometric coefficients
                !
                StartInd=index(ChemInpLine,'>')+1
                if (StartInd==1) StartInd=index(ChemInpLine,'=')+1
                SeparatorInd=index(ChemInpLine(StartInd:),' ')+StartInd-1
                !
                ParanthesisInd=index(ChemInpLine(StartInd:),'(+M)')+StartInd-1
                if (ParanthesisInd>StartInd) then
                  LastLeftCharacter=min(ParanthesisInd,SeparatorInd)-1
                else
                  LastLeftCharacter=SeparatorInd-1
                endif
                PlusInd=index(ChemInpLine(StartInd:LastLeftCharacter),'+')&
                     +StartInd-1
                do while (PlusInd<LastLeftCharacter .AND. PlusInd>StartInd)
                  StopInd=PlusInd-1
                  call build_stoich_matrix(StartInd,StopInd,k,ChemInpLine,.true.)
                  StartInd=StopInd+2
                  PlusInd=index(ChemInpLine(StartInd:),'+')+StartInd-1
                enddo
                StopInd=LastLeftCharacter
                call build_stoich_matrix(StartInd,StopInd,k,ChemInpLine,.true.)
                !
                ! Find Arrhenius coefficients
                !
!                print*,'Start reading Arrhenius coefficients.'
                VarNumber=1; StartInd=1; StopInd =0
                stringloop: do while (VarNumber<4)
                  StopInd=index(ChemInpLine(StartInd:),' ')+StartInd-1
                  StartInd=verify(ChemInpLine(StopInd:),' ')+StopInd-1
                  StopInd=index(ChemInpLine(StartInd:),' ')+StartInd-1
                  if (StopInd==StartInd) then
                    StartInd=StartInd+1
                  else
                    if (VarNumber==1) then
                      read (unit=ChemInpLine(StartInd:StopInd),fmt='(E15.8)')  &
                           B_n(k)
                    elseif (VarNumber==2) then
                      read (unit=ChemInpLine(StartInd:StopInd),fmt='(E15.8)')  &
                           alpha_n(k)
                    elseif (VarNumber==3) then
                      read (unit=ChemInpLine(StartInd:StopInd),fmt='(E15.8)')  &
                           E_an(k)
                    else
                      call stop_it("No such VarNumber!")
                    endif
                    VarNumber=VarNumber+1
                    StartInd=StopInd
                  endif
                  if (StartInd==80) exit
                enddo stringloop
                !
                ! Increase reaction counter by one
                !
                k=k+1
              endif
            endif
          endif
        endif
      enddo dataloop3
1012  continue
      close(file_id)
      !
    end subroutine read_reactions
 !********************************************************************
    subroutine write_thermodyn()
      !
      ! This subroutine writes the thermodynamical data for every specie
      ! to ./data/chem.out. 
      !
      ! 2008.03.06 Nils Erland: Coded
      !
      character (len=20) :: input_file="./data/chem.out"
      integer :: file_id=123,k
      !
      open(file_id,file=input_file)
      write(file_id,*) 'Specie'
      write(file_id,*) 'MolMass Temp1 Temp2 Temp3'
      write(file_id,*) 'a1(1)  a1(2)  a1(3)  a1(4)  a1(5)  a1(6)  a1(7)'
      write(file_id,*) 'a2(1)  a2(2)  a2(3)  a2(4)  a2(5)  a2(6)  a2(7)'
      write(file_id,*) '***********************************************'
      dataloop2: do k=1,nchemspec
        write(file_id,*) varname(ichemspec(k))
        write(file_id,'(F10.2,3F10.2)') species_constants(k,imass),&
             species_constants(k,iTemp1:iTemp3)
        write(file_id,'(7E10.2)') species_constants(k,ia1)
        write(file_id,'(7E10.2)') species_constants(k,ia2)
      enddo dataloop2
      !
      close(file_id)
      !
    end subroutine write_thermodyn
!***************************************************************
    subroutine build_stoich_matrix(StartInd,StopInd,k,ChemInpLine,product)
      !
      ! 2008.03.10 Nils Erland: Coded
      !
      use Mpicomm
      !
      integer, intent(in) :: StartInd,StopInd,k
      character (len=*), intent(in) :: ChemInpLine
      integer :: StartSpecie,ind_glob,ind_chem,stoi
      logical :: found_specie,product
      !
      if (ChemInpLine(StartInd:StopInd) /= "M" ) then
        StartSpecie=verify(ChemInpLine(StartInd:StopInd),"1234567890")+StartInd-1
        call find_species_index(ChemInpLine(StartSpecie:StopInd),&
             ind_glob,ind_chem,found_specie)
        if (.not. found_specie) call stop_it("Did not find specie!")
        if (StartSpecie==StartInd) then
          stoi=1
        else
          read (unit=ChemInpLine(StartInd:StartInd),fmt='(I1)') stoi
        endif
        if (product) then
          Sijm(ind_chem,k)=Sijm(ind_chem,k)+stoi
        else
          Sijp(ind_chem,k)=Sijp(ind_chem,k)+stoi
        endif
      endif
      !
    end subroutine build_stoich_matrix
    !***************************************************************
    subroutine write_reactions()
      !
      ! 2008.03.11 Nils Erland: Coded
      !
      use General, only: chn
      !
      integer :: reac,spec
      character (len=80) :: reac_string,product_string,output_string
      character (len=5)  :: Sijp_string,Sijm_string
      character (len=1)  :: separatorp,separatorm
      character (len=20) :: input_file="./data/chem.out"
      integer :: file_id=123
      !
      open(file_id,file=input_file,POSITION='APPEND',FORM='FORMATTED')
      write(file_id,*) 'REACTIONS'
!      open(file_id,file=input_file)
      do reac=1,mreactions
          reac_string=''
          product_string=''
          separatorp=''
          separatorm=''
          do spec=1,nchemspec
            if (Sijp(spec,reac)>0) then
              Sijp_string=''
              if (Sijp(spec,reac)>1) call chn(Sijp(spec,reac),Sijp_string)
              reac_string=trim(reac_string)//trim(separatorp)//&
                   trim(Sijp_string)//trim(varname(ichemspec(spec)))
              separatorp='+'
            endif
            if (Sijm(spec,reac)>0) then
              Sijm_string=''
              if (Sijm(spec,reac)>1) call chn(Sijm(spec,reac),Sijm_string)
              product_string=trim(product_string)//trim(separatorm)//&
                   trim(Sijm_string)//trim(varname(ichemspec(spec)))
              separatorm='+'
            endif
          enddo
          output_string=trim(reac_string)//'='//trim(product_string)
          write(unit=output_string(30:45),fmt='(E14.4)') B_n(reac)
          write(unit=output_string(47:62),fmt='(E14.4)') alpha_n(reac)
          write(unit=output_string(64:79),fmt='(E14.4)') E_an(reac)
          write(file_id,*) trim(output_string)
        enddo
        write(file_id,*) 'END'
        close(file_id)
        !
      end subroutine write_reactions
!***************************************************************
   subroutine get_reaction_rate(f,vreact_p,vreact_m)
!Natalia (17.03.2008)
!This subroutine calculates forward and reverse reaction rates, if chem.inp file exists.
!For more details see Chemkin Theory Manual
!
    real, dimension (mx,my,mz,mfarray) :: f 
    intent(in) :: f
    type (pencil_case) :: p
    real, dimension (nx) :: dSR=0.,dHRT=0.,Kp,Kc,prod1=0.,prod2=0.
    real, dimension (nx) :: kreac_array_pk=0., kreac_array_mk=0.

    real, dimension (nx,nreactions), intent(out) :: vreact_p, vreact_m

     integer :: k , reac
     real  :: sum_tmp=0.

!


    do reac=1,nreactions

     kreac_array_pk(:)=B_n(reac)*(p%TT(:)*unit_temperature)**alpha_n(reac)*exp(E_an(reac)/Rgas_unit_sys/p%TT(:)/unit_temperature)

     do k=1,nchemspec
       dSR(:) =dSR(:)+(Sijm(k,reac)-Sijp(k,reac))*p%S0R(:,k)
       dHRT(:)=dHRT(:)+(Sijm(k,reac)-Sijp(k,reac))*p%H0RT(:,k)
       sum_tmp=sum_tmp+(Sijm(k,reac)-Sijp(k,reac))
     enddo

     Kp=exp(dSR-dHRT)

     Kc=Kp*(p%pp/p%TT/Rgas_unit_sys/0.986*unit_mass/unit_length/unit_time**2/unit_temperature)**sum_tmp

     kreac_array_mk(:)=kreac_array_pk(:)/Kc

      do k=1,nchemspec   
       prod1=prod1*f(l1:l2,m,n,ichemspec(k))**Sijp(k,reac)
      enddo
      do k=1,nchemspec   
       prod2=prod2*f(l1:l2,m,n,ichemspec(k))**Sijm(k,reac)
      enddo
       vreact_p(:,reac)=kreac_array_pk*prod1
       vreact_m(:,reac)=kreac_array_mk*prod2

    enddo

   end subroutine get_reaction_rate
!***************************************************************
!********************************************************************
!************        DO NOT DELETE THE FOLLOWING       **************
!********************************************************************
!**  This is an automatically generated include file that creates  **
!**  copies dummy routines from nospecial.f90 for any Special      **
!**  routines not implemented in this file                         **
!**                                                                **
    include 'special_dummies.inc'
!********************************************************************

endmodule Chemistry

