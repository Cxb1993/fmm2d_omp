cc Copyright (C) 2010-2011: Leslie Greengard and Zydrunas Gimbutas
cc Contact: greengard@cims.nyu.edu
cc 
cc This program is free software; you can redistribute it and/or modify 
cc it under the terms of the GNU General Public License as published by 
cc the Free Software Foundation; either version 2 of the License, or 
cc (at your option) any later version.  This program is distributed in 
cc the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
cc even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
cc PARTICULAR PURPOSE.  See the GNU General Public License for more 
cc details. You should have received a copy of the GNU General Public 
cc License along with this program; 
cc if not, see <http://www.gnu.org/licenses/>.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c    $Date$
c    $Revision$
c
c       
c
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c        this is the end of the debugging code and the beginning 
c        of the routines for Helmholtz FMM in R^2
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c
c
        subroutine lfmm2dparttree(ier,iprec,
     $     nsource,source,ntarget,target,
     $     nbox,epsfmm,iisource,iitarget,iwlists,lwlists,
     $     nboxes,laddr,nlev,center,size,
     $     w,lw,lused7)
        implicit real *8 (a-h,o-z)
c       
c       Helmholtz FMM in R^2: build the quad-tree
c
c     INPUT PARAMETERS:
c
c       nsource: integer:  number of sources
c       source: real *8 (2,n):  source locations
c       w: real *8 (lw): workspace
c       lw:  length of workspace
c
c     OUTPUT PARAMETERS:
c
c       ier   =  error return code
c       lused7 = the amount of workspace used
c
c
        real *8 source(2,*),target(2,*)
c       
        real *8 center(2)
c       
        integer laddr(2,200)
        integer box(15)
        real *8 center0(2),corners0(2,4)
c       
        integer box1(15)
        real *8 center1(2),corners1(2,4)
c
        real *8 w(*)
c       
        ier=0
c       
        done=1
        pi=4*atan(done)
c       
        lused7=0
        ifprint=0
c       
        iisource=1
        lused7=lused7+nsource
        if (ifprint.eq.1) call prinf('lused7=*',lused7,1)
        if (lused7 .ge. lw) ier=128
        if( ier .ne. 0 ) return
c
        iitarget=iisource+nsource
        lused7=lused7+ntarget
        if (ifprint.eq.1) call prinf('lused7=*',lused7,1)
        if (lused7 .ge. lw) ier=128
        if( ier .ne. 0 ) return
c
        iwlists=iisource+lused7+10
c
c       ... construct the adaptive FMM quad-tree structure
c
c        call d2tstrcr(ier,source,nsource,nbox,
c     $     nboxes,w(iisource),laddr,nlev,center,size,
c     $     target,ntarget,w(iitarget),w(iwlists),lw-lused7,lused)
        ifempty=0
        minlevel=0
        maxlevel=30
        call d2tstrcrem(ier,source,nsource,nbox,
     $     nboxes,w(iisource),laddr,nlev,center,size,
     $     target,ntarget,w(iitarget),w(iwlists),lw-lused7,lused,
     $     ifempty,minlevel,maxlevel)
c
        if( ier .ne. 0 ) return
c
        lwlists=lused
        lused7=lused7+lwlists
        if (lused7 .ge. lw) ier=128
        if( ier .ne. 0 ) return
c       
        if (ifprint.eq.1) 
     $       call prin2('after d2tstrcr, center=*',center,2)
        if (ifprint.eq.1) 
     $       call prin2('after d2tstrcr, size=*',size,1)
        if (ifprint.eq.1) 
     $       call prinf('after d2tstrcr, nlev=*',nlev,1)
        if (ifprint.eq.1) 
     $       call prinf('after d2tstrcr, nbox=*',nbox,1)
        if (ifprint.eq.1) 
     $       call prinf('after d2tstrcr, laddr=*',laddr,2*(nlev+1))
c
ccc        call prinf('after d2tstrcr, isource=*',w(iisource),nsource)
ccc        call prinf('after d2tstrcr, itarget=*',w(iitarget),ntarget)
c
ccc        call d2tprint(w(iwlists),lwlists)
c
c       ... optional, plot the oct-tree in gnuplot compatible format
c
        ifplot = 0
        if (ifplot .eq. 1 .and. nsource .lt. 10000 ) then
c
c       ... plot the boxes
c
        iw=51
        call plot_box2d(iw,center,size)
c       
        itag=1
        iw=52
        call plot_label2d(iw,center,size,itag,itag)
c
        iw=60
        call plot_points2d(iw,source,nsource)
c       
        iw=63
        call plot_points2d(iw,target,ntarget)
c       
        do ibox=1,nboxes
           call d2tgetb(ier,ibox,box,center0,corners0,w(iwlists))
           level=box(1)
           size0=size/2**level
c
           iw=61
           call plot_box2d(iw,center0,size0)
c       
           itag=ibox
           iw=62
           call plot_label2d(iw,center0,size0,itag,itag)
        enddo  
c      
        endif
c
        return
        end
c
c
c
c
c
        subroutine lfmm2d_list2
     $     (bsize,nlev,laddr,scale,nterms,rmlexp,iaddr,epsfmm,
     $     timeinfo,wlists,mptemp,lmptemp,
     $     ifprune_list2)
        implicit real *8 (a-h,o-z)
c
        integer iaddr(2,*),laddr(2,*),nterms(0:*)
        real *8 rmlexp(*),scale(0:*)
        integer itable(-3:3,-3:3)
c
        integer list(10 000)
c
        integer box(15)
        real *8 bsize(0:200)
        real *8 center0(2),corners0(2,4)
c       
        integer box1(15)
        real *8 center1(2),corners1(2,4)
c
        real *8 wlists(*)
        complex *16 mptemp(lmptemp)
        complex *16 ptemp,ftemp(2),htemp(3)
c
        real *8 timeinfo(10)
c
        real *8, allocatable :: carray(:,:)
c               
c
        ldc = 100
        allocate( carray(0:ldc,0:ldc) )
        call l2d_init_carray(carray,ldc)
c
c
c     ifprint is an internal information printing flag. 
c     Suppressed if ifprint=0.
c     Prints timing breakdown and other things if ifprint=1.
c     Prints timing breakdown, list information, and other things if ifprint=2.
c       
        ifprint=1
c
         if (ifprint .ge. 1) 
     $     call prinf('=== STEP 3 (merge mp) ===*',i,0)
         t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 3, merge all multipole expansions
c       
ccc         do 2200 ibox=nboxes,1,-1





C$OMP PARALLEL DEFAULT(SHARED)
C$OMP$PRIVATE(ibox,box,center0,corners0,level0,level,npts,nkids,radius)
C$OMP$PRIVATE(jbox,box1,center1,corners1,level1)
C$OMP$PRIVATE(mptemp,lused,ier,i,j,ptemp,ftemp,cd) 
C$OMP$PRIVATE(list,nlists,nlist,itype)
C$OMP$PRIVATE(ifdirect2)
C$OMP$PRIVATE(htemp,ilist)
C$OMP$PRIVATE(if_use_trunc,nterms_trunc,ii,jj) 

         do 2300 ilev=nlev,3,-1


C$OMP DO SCHEDULE(DYNAMIC)


         do 2200 ibox=laddr(1,ilev),laddr(1,ilev)+laddr(2,ilev)-1
c
         call d2tgetb(ier,ibox,box,center0,corners0,wlists)
         call d2tnkids(box,nkids)
c
c       ... prune all sourceless boxes
c
         if( box(10) .eq. 0 ) goto 2200
c
         if (nkids .ne. 0) then
c
         level0=box(1)
         if( level0 .ge. 2 ) then
ccc         if (level0 .ge. 0) then
            radius = (corners0(1,1) - center0(1))**2
            radius = radius + (corners0(2,1) - center0(2))**2
            radius = sqrt(radius)
c       
            if( ifprint .ge. 2 ) then
               call prin2('radius=*',radius,1)
               call prinf('ibox=*',ibox,1)
               call prinf('box=*',box,15)
               call prinf('nkids=*',nkids,1)
            endif
c
c       ... merge multipole expansions of the kids 
c
            call l2dzero(rmlexp(iaddr(1,ibox)),nterms(level0))
            if (ifprint .ge. 2) then
               call prin2('center0=*',center0,2)
            endif
c
            do 2100 i = 1,4
               jbox = box(4+i)
               if (jbox.eq.0) goto 2100
               call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
               if (ifprint .ge. 2) then
               call prinf('jbox=*',jbox,1)
               call prin2('center1=*',center1,2)
               endif
               level1=box1(1)
c       SUNLI: DON'T UNDERSTAND THIS
               if( nterms(level0)+nterms(level1) .gt. 95 ) then
               call l2dmpmp(scale(level1),center1,
     1            rmlexp(iaddr(1,jbox)),nterms(level1),scale(level0),
     1            center0,mptemp,nterms(level0))
               else
               call l2dmpmp_carray(scale(level1),center1,
     1            rmlexp(iaddr(1,jbox)),nterms(level1),scale(level0),
     1            center0,mptemp,nterms(level0),carray,ldc)
               endif
               call l2dadd(mptemp,rmlexp(iaddr(1,ibox)),
     1            nterms(level0))
 2100       continue
            if (ifprint .ge. 2) then
            call prinf('=============*',x,0)
            endif
c       ... mark the local expansion of all kids and the parent
c
            endif
         endif
 2200    continue


C$OMP END DO



 2300    continue
c
c
ccc        call prinf('=== UPWARD PASS COMPLETE ===*',i,0)
c
c------------------------------------------------------------
c      DEBUGGING SEGMENT - once all multipole expansions are merged
c      to top level, one can compare it to the direct formation of the
c      expansion at the top level from the source locations.
c
ccc        call prinm(rmlexp(iaddr(1,1)),nterms(0))
c
ccc        call h2dformmp(ier,scale(0),source,charge,n,
ccc     1  	center,nterms(0),mptemp)
c
ccc        call prinm(mptemp,nterms(0))
c
ccc        call h2dmperr(rmlexp(iaddr(1,1)),mptemp,nterms(0),d)
ccc        call prin2('error in upward pass=*',d,1)
c
ccc        pause
ccc        stop
c      END DEBUGGING SEGMENT
c------------------------------------------------------------
c
         t2=second()
C$        t2=omp_get_wtime()
ccc        call prin2('time=*',t2-t1,1)
         timeinfo(3)=t2-t1
c
        if (ifprint .ge. 1) 
     $     call prinf('=== STEP 4 (mp to lo) ===*',i,0)
        t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 4, convert multipole expansions into the local ones
c
cc        call prinf('laddr=*',laddr,2*(nlev+1))
cc        call prin2('bsize=*',bsize,(nlev+1))
cc        do 4200 ibox=1,nboxes
ccc        ntops=0

        call l2dterms_list2(epsfmm, itable, ier)
c        call prinf('itable=*',itable,7*7)
c
        do 4300 ilev=3,nlev+1
c        t3=second()
cC$        t3=omp_get_wtime()
C$OMP DO SCHEDULE(DYNAMIC)
        do 4200 ibox=laddr(1,ilev),laddr(1,ilev)+laddr(2,ilev)-1
        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        if (ifprint .ge. 2) then
           call prinf('ibox=*',ibox,1)
           call prinf('box=*',box,15)
        endif
        level0=box(1)
        if (level0 .ge. 2) then
c
c       ... retrieve list #2
c
           itype=2
           call d2tgetl(ier,ibox,itype,list,nlist,wlists)
           if (ifprint .ge. 2) then
              call prinf('list2=*',list,nlist)
           endif
c
c       ... prune all sourceless boxes
c
ccc           if( box(10) .eq. 0 ) nlist=0

c       ... for all pairs in list #2, apply the translation operator 
c
           do 4150 ilist=1,nlist
              jbox=list(ilist)
              call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
              if( box1(10) .eq. 0 ) goto 4150
              if (jbox.eq.0) goto 4150
              if ((box(12).eq.0).and.(ifprune_list2.eq.1))
     $           goto 4150
c              radius = (corners1(1,1) - center1(1))**2
c              radius = radius + (corners1(2,1) - center1(2))**2
c              radius = sqrt(radius)
c
c       ... convert multipole expansions for all boxes in list 2 in local exp
c       ... if source is childless, evaluate directly (if cheaper)
c

              level1=box1(1)
c              ifdirect2 = 0
c              if( box1(10) .lt. (nterms(level1)+1)/2 .and. 
c     $            box(10) .lt. (nterms(level1)+1)/2  ) 
c     $               ifdirect2 = 1        
c
              ifdirect2 = 0
c
              if_use_trunc = 0
c       SUNLI: WHAT IS THIS VARIABLE?
c
              if (ifdirect2 .eq. 0) then
              if( if_use_trunc .eq. 0) then

                 call l2dzero(mptemp,nterms(level1))
                 if( nterms(level0)+nterms(level1) .gt. 95 ) then
                 call l2dmploc(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms(level1),
     $              scale(level0),
     1              center0,mptemp,nterms(level0))
                 else
                 call l2dmploc_carray(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms(level1),
     $              scale(level0),
     1              center0,mptemp,nterms(level0),
     $              carray,ldc)
                 endif
                 call l2dadd(mptemp,rmlexp(iaddr(2,ibox)),
     1              nterms(level0))
c
c              call l2dmploc_add(scale(level1),center1,
c     $           rmlexp(iaddr(1,jbox)),nterms(level1),
c     $           scale(level0),center0,rmlexp(iaddr(2,ibox)),
c     $           nterms(level0))

              else

              ii=box1(2)-box(2)
              jj=box1(3)-box(3)
              nterms_trunc=itable(ii,jj)
              nterms_trunc=min(nterms(level0),nterms_trunc)
              nterms_trunc=min(nterms(level1),nterms_trunc)

                 call l2dzero(mptemp,nterms_trunc)
                 if( nterms_trunc+nterms_trunc .gt. 95 ) then
                 call l2dmploc(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms_trunc,
     $              scale(level0),
     1              center0,mptemp,nterms_trunc)
                 else
                 call l2dmploc_carray(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms_trunc,
     $              scale(level0),
     1              center0,mptemp,nterms_trunc,
     $              carray,ldc)
                 endif
                 call l2dadd(mptemp,rmlexp(iaddr(2,ibox)),
     1              nterms_trunc)

c              call l2dmploc_add_trunc(scale(level1),center1,
c     $           rmlexp(iaddr(1,jbox)),nterms(level1),nterms_trunc,
c     $           scale(level0),center0,rmlexp(iaddr(2,ibox)),
c     $           nterms(level0))

c              call l2dmploc_add(scale(level1),center1,
c     $           rmlexp(iaddr(1,jbox)),nterms_trunc,
c     $           scale(level0),center0,rmlexp(iaddr(2,ibox)),
c     $           nterms_trunc)

              endif
              endif

 4150       continue
        endif
 4200   continue
C$OMP END DO
c        t4=second()
cC$        t4=omp_get_wtime()
c        write(*,*) 'level ', ilev, ' time in list2:', t4-t3
ccc        write(*,*) 'time in list2:', second()-t1
ccc        write(*,*) 'ntops:', ntops
ccc        write(*,*) 'speed:', ntops/(second()-t1)
 4300   continue
c
        t2=second()
C$        t2=omp_get_wtime()
ccc     call prin2('time=*',t2-t1,1)
        timeinfo(4)=t2-t1
c       
        if (ifprint .ge. 1) 
     $     call prinf('=== STEP 5 (split lo) ===*',i,0)
        t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 5, split all local expansions
c
ccc        do 5200 ibox=1,nboxes
        do 5300 ilev=3,nlev




C$OMP DO SCHEDULE(DYNAMIC)



cccC$OMP$NUM_THREADS(4) 
        do 5200 ibox=laddr(1,ilev),laddr(1,ilev)+laddr(2,ilev)-1
c
        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        call d2tnkids(box,nkids)
c       
        if (nkids .ne. 0) then
            level0=box(1)
            if (level0 .ge. 2) then
               if (ifprint .ge. 2) then
                  call prinf('ibox=*',ibox,1)
                  call prinf('box=*',box,15)
                  call prinf('nkids=*',nkids,1)
                  call prin2('center0=*',center0,2)
               endif
c
c       ... split local expansion of the parent box
c
               do 5100 i = 1,4
	          jbox = box(4+i)
	          if (jbox.eq.0) goto 5100
                  call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
                  radius = (corners1(1,1) - center1(1))**2
                  radius = radius + (corners1(2,1) - center1(2))**2
                  radius = sqrt(radius)
                  if (ifprint .ge. 2) then
                     call prinf('jbox=*',jbox,1)
                     call prin2('radius=*',radius,1)
                     call prin2('center1=*',center1,2)
                  endif
                  level1=box1(1)
                  if( nterms(level0)+nterms(level1) .gt. 95 ) then
                  call l2dlocloc(scale(level0),center0,
     1               rmlexp(iaddr(2,ibox)),nterms(level0),
     1               scale(level1),center1,mptemp,nterms(level1))
                  else
                  call l2dlocloc_carray(scale(level0),center0,
     1               rmlexp(iaddr(2,ibox)),nterms(level0),
     1               scale(level1),center1,mptemp,nterms(level1),
     1               carray,ldc)
                  endif
                  call l2dadd(mptemp,rmlexp(iaddr(2,jbox)),
     1   	       nterms(level1))
 5100          continue
               if (ifprint .ge. 2) call prinf('=============*',x,0)
            endif
        endif
c
        if (nkids .ne. 0) then
            level=box(1)
            if (level .ge. 2) then
               if( ifprint .ge. 2 ) then
                  call prinf('ibox=*',ibox,1)
                  call prinf('box=*',box,15)
                  call prinf('nkids=*',nkids,1)
               endif
            endif
        endif
 5200   continue
C$OMP END DO
 5300   continue
c       
        t2=second()
C$        t2=omp_get_wtime()
ccc     call prin2('time=*',t2-t1,1)
        timeinfo(5)=t2-t1
c

C$OMP END PARALLEL


        return
        end

































        subroutine lfmm2d_list2_hideP2T
     $     (bsize,nlev,laddr,scale,nterms,rmlexp,iaddr,epsfmm,
     $     timeinfo,wlists,mptemp,lmptemp,
     $     ifprune_list2,
     $     nboxes,sourcesort,isource, ifcharge,chargesort,ifdipole,
     $     dipstrsort,ifpot,pot,ifgrad,grad,ifhess,hess,
     $     targetsort,ifpottarg,pottarg,ifgradtarg,gradtarg,
     $     ifhesstarg,hesstarg,ifevalloc,
     $     CHUNK_SIZE_P2T, CHUNK_SIZE_M2M, CHUNK_SIZE_M2L,
     $     CHUNK_SIZE_P2M)


        implicit real *8 (a-h,o-z)
c
        integer iaddr(2,*),laddr(2,*),nterms(0:*)
        real *8 rmlexp(*),scale(0:*)
        integer itable(-3:3,-3:3)
c
        integer list(10 000)
c
        integer box(15)
        real *8 bsize(0:200)
        real *8 center0(2),corners0(2,4)
c       
        integer box1(15)
        real *8 center1(2),corners1(2,4)
c
        real *8 wlists(*)
        complex *16 mptemp(lmptemp)
        complex *16 ptemp,ftemp(2),htemp(3)
c
        real *8 timeinfo(10)
c
        real *8, allocatable :: carray(:,:)


c       SUNLI: NEW VARIABLES
c        integer nlist, npts, itype
        real *8 sourcesort(2,*)
        integer isource(*)
        complex *16 chargesort(*)
        complex *16 dipstrsort(*)
        complex *16 pot(*)
        complex *16 grad(*)
        complex *16 hess(*)
        real *8 targetsort(2,*)
        complex *16 pottarg(*)
        complex *16 gradtarg(*)
        complex *16 hesstarg(*)

c       SUNLI: Test CHUNK_SIZE: see if change graularity gives any
c               improvement in speed. CHUNK_SIZE2 is for p2t loops, and
c               CHUNK_SIZE1 is for others. In future, should make these
c               two variable as input, instead of parameter.
        integer CHUNK_SIZE_P2T, CHUNK_SIZE_M2M, CHUNK_SIZE_M2L
        integer CHUNK_SIZE_P2M
cccc        real *8 TIME_THREADS(32,64), tt(32)

c        CHUNK_SIZE_P2T = 1
c        CHUNK_SIZE_M2M = 1
c        CHUNK_SIZE_M2L = 1


c               
c
        ldc = 100
        allocate( carray(0:ldc,0:ldc) )
        call l2d_init_carray(carray,ldc)
c
c
c     ifprint is an internal information printing flag. 
c     Suppressed if ifprint=0.
c     Prints timing breakdown and other things if ifprint=1.
c     Prints timing breakdown, list information, and other things if ifprint=2.
c       
        ifprint=0

c=============================================================================
c   SUNLI: Put P2M computation here so that we can change it to
c          task-based parallel model.
c=============================================================================



        call prinf("nboxes = *",nboxes,1)

        if(ifprint .ge. 1) 
     $     call prinf('=== STEP 1 (form mp) ====*',i,0)
        t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 1, locate all charges, assign them to boxes, and
c       form multipole expansions
c


C$OMP PARALLEL DEFAULT(SHARED)
C$OMP$PRIVATE(ibox,box,center0,corners0,level0,level,npts,nkids,radius)
C$OMP$PRIVATE(jbox,box1,center1,corners1,level1)
C$OMP$PRIVATE(mptemp,lused,ier,i,j,ptemp,ftemp,cd) 
C$OMP$PRIVATE(list,nlists,nlist,itype)
C$OMP$PRIVATE(ifdirect2)
C$OMP$PRIVATE(htemp,ilist)
C$OMP$PRIVATE(if_use_trunc,nterms_trunc,ii,jj) 
C$OMP$PRIVATE(ibox2)
C$OMP$PRIVATE(gtemp)
C$OMP$PRIVATE(tt)
C$OMP$PRIVATE(ibox_start,ibox_end,nCHUNK_LEFT)
C$OMP$PRIVATE(ibox_start2,ibox_end2, ichunk)

c=============================================================================
c   SUNLI: Put P2T computation here: since it is independent to any
c          other steps, we are free to put it anywhere. One good
c          strategy is to put it between M2M and M2L -- since M2L is
c          independent between levels, we can put NOWAIT for both P2T
c          and M2L and synchronize before starting L2L
c=============================================================================


         if (ifprint .ge. 1) 
     $     call prinf('=== STEP 8 (direct) =====*',i,0)
        t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 8, evaluate direct interactions 
c

c       SUNLI: Not task-based yet. Need to change omp do loop to
c         omp single/section and omp task inside the loop
c        [TASK-BASED]

C$OMP SECTIONS

C$OMP SECTION
        do 1020 ichunk=1,nboxes / CHUNK_SIZE_P2T
          ibox_start = (ichunk-1) * CHUNK_SIZE_P2T + 1
C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ibox_start)

          call P2T_task (ibox_start, CHUNK_SIZE_P2T, wlists,
     $     sourcesort, ifcharge,chargesort,ifdipole,dipstrsort,
     $     ifpot,pot,ifgrad,grad,ifhess,hess,
     $     targetsort,ifpottarg,pottarg,ifgradtarg,gradtarg,
     $     ifhesstarg,hesstarg)
C$OMP END TASK

 1020   continue

c     SUNLI: compute leftover

        ibox_start2 = nboxes / CHUNK_SIZE_P2M * CHUNK_SIZE_P2M + 1
        nCHUNK_LEFT = nboxes - ibox_start2  + 1

c      print *, "ibox_start2 = ",ibox_start2
c      print *, "nboxes = ",nboxes
      
C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ibox_start2)
          call P2T_task (ibox_start2, nCHUNK_LEFT, wlists,
     $     sourcesort, ifcharge,chargesort,ifdipole,dipstrsort,
     $     ifpot,pot,ifgrad,grad,ifhess,hess,
     $     targetsort,ifpottarg,pottarg,ifgradtarg,gradtarg,
     $     ifhesstarg,hesstarg)

C$OMP END TASK


c
ccc        call prin2('inside fmm, pot=*',pot,2*nsource)
ccc        call prin2('inside fmm, grad=*',grad,2*nsource)
ccc        call prin2('inside fmm, hess=*',hess,2*nsource)
c
c
        t2=second()
C$        t2=omp_get_wtime()
ccc     call prin2('time=*',t2-t1,1)
        timeinfo(8)=t2-t1
c
c
ccc        call prinf('=== DOWNWARD PASS COMPLETE ===*',i,0)





c=======================================================================
c     P2M
c
c
c
c
c=======================================================================

C$OMP SECTION

        do 1200 ichunk=1,nboxes / CHUNK_SIZE_P2M

          ibox_start = (ichunk-1) * CHUNK_SIZE_P2M + 1
c          call prinf("ibox_start = *", ibox_start,1)

C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ibox_start)

        call P2M_task (ibox_start, CHUNK_SIZE_P2M, wlists,
     $     sourcesort, ifcharge,chargesort,ifdipole,dipstrsort,
     $     rmlexp, scale, mptemp, lmptemp, iaddr, nterms)


C$OMP END TASK

 1200    continue

        ibox_start2 = nboxes / CHUNK_SIZE_P2M * CHUNK_SIZE_P2M + 1
        nCHUNK_LEFT = nboxes - ibox_start2  + 1

c        print *, "P2M_ibox_start2 = ",ibox_start2
c        print *, "finest level nboxes = ",nboxes

c        go to 1300


C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ibox_start2)
        call P2M_task (ibox_start2, nCHUNK_LEFT, wlists,
     $     sourcesort, ifcharge,chargesort,ifdipole,dipstrsort,
     $     rmlexp, scale, mptemp, lmptemp, iaddr, nterms)

C$OMP END TASK

C$OMP TASKWAIT



c=======================================================================
c     M2M
c
c
c
c
c=======================================================================



c
         if (ifprint .ge. 1) 
     $     call prinf('=== STEP 3 (merge mp) ===*',i,0)
         t1=second()
c       ... step 3, merge all multipole expansions
c       

         do 2300 ilev=nlev,3,-1
c        print *, "ilev = ", ilev

         do 2200 ichunk = 1,laddr(2,ilev)/CHUNK_SIZE_M2M

C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ichunk,ilev)
C$OMP$PRIVATE(ibox_start, ibox_end, ier, ibox, box, center0, corners0)
C$OMP$PRIVATE(nkids, level0, radius, i, jbox, box1, center1, corners1)
C$OMP$PRIVATE(level1, mptemp)

           ibox_start = (ichunk - 1) * CHUNK_SIZE_M2M + laddr(1,ilev)
           ibox_end = ibox_start + CHUNK_SIZE_M2M - 1
c        print *, "ibox_start = ", ibox_start
c        print *, "ibox_end = ", ibox_end


           do 2150 ibox = ibox_start, ibox_end
c
         call d2tgetb(ier,ibox,box,center0,corners0,wlists)
         call d2tnkids(box,nkids)
c
c       ... prune all sourceless boxes
c
         if( box(10) .eq. 0 ) goto 2150
c
         if (nkids .ne. 0) then
c
         level0=box(1)
         if( level0 .ge. 2 ) then
ccc         if (level0 .ge. 0) then
            radius = (corners0(1,1) - center0(1))**2
            radius = radius + (corners0(2,1) - center0(2))**2
            radius = sqrt(radius)
c       
            if( ifprint .ge. 2 ) then
               call prin2('radius=*',radius,1)
               call prinf('ibox=*',ibox,1)
               call prinf('box=*',box,15)
               call prinf('nkids=*',nkids,1)
            endif
c
c       ... merge multipole expansions of the kids 
c
            call l2dzero(rmlexp(iaddr(1,ibox)),nterms(level0))
            if (ifprint .ge. 2) then
               call prin2('center0=*',center0,2)
            endif
c
            do 2100 i = 1,4
               jbox = box(4+i)
               if (jbox.eq.0) goto 2100
               call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
               if (ifprint .ge. 2) then
               call prinf('jbox=*',jbox,1)
               call prin2('center1=*',center1,2)
               endif
               level1=box1(1)
               if( nterms(level0)+nterms(level1) .gt. 95 ) then
               call l2dmpmp(scale(level1),center1,
     1            rmlexp(iaddr(1,jbox)),nterms(level1),scale(level0),
     1            center0,mptemp,nterms(level0))
               else
               call l2dmpmp_carray(scale(level1),center1,
     1            rmlexp(iaddr(1,jbox)),nterms(level1),scale(level0),
     1            center0,mptemp,nterms(level0),carray,ldc)
               endif
               call l2dadd(mptemp,rmlexp(iaddr(1,ibox)),
     1            nterms(level0))
 2100       continue
            if (ifprint .ge. 2) then
            call prinf('=============*',x,0)
            endif
c       ... mark the local expansion of all kids and the parent
c
            endif
         endif
 2150    continue

C$OMP END TASK

 2200    continue




C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ilev)
C$OMP$PRIVATE(ibox_start2, ibox_end2, ier, ibox, box, center0, corners0)
C$OMP$PRIVATE(nkids, level0, radius, i, jbox, box1, center1, corners1)
C$OMP$PRIVATE(level1, mptemp)

        ibox_start2 = laddr(2,ilev) / CHUNK_SIZE_M2M * CHUNK_SIZE_M2M
        ibox_start2 = ibox_start2 + laddr(1,ilev)
        ibox_end2 = laddr(1,ilev)+laddr(2,ilev)-1
        
c        print *, "ibox_start2 = ", ibox_start2
c        print *, "ibox_end2 = ", ibox_end2

           do 2250 ibox = ibox_start2, ibox_end2
c
         call d2tgetb(ier,ibox,box,center0,corners0,wlists)
         call d2tnkids(box,nkids)
c
c       ... prune all sourceless boxes
c
         if( box(10) .eq. 0 ) goto 2250
c
         if (nkids .ne. 0) then
c
         level0=box(1)
         if( level0 .ge. 2 ) then
ccc         if (level0 .ge. 0) then
            radius = (corners0(1,1) - center0(1))**2
            radius = radius + (corners0(2,1) - center0(2))**2
            radius = sqrt(radius)
c       
            if( ifprint .ge. 2 ) then
               call prin2('radius=*',radius,1)
               call prinf('ibox=*',ibox,1)
               call prinf('box=*',box,15)
               call prinf('nkids=*',nkids,1)
            endif
c
c       ... merge multipole expansions of the kids 
c
            call l2dzero(rmlexp(iaddr(1,ibox)),nterms(level0))
            if (ifprint .ge. 2) then
               call prin2('center0=*',center0,2)
            endif
c
            do 2220 i = 1,4
               jbox = box(4+i)
               if (jbox.eq.0) goto 2220
               call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
               if (ifprint .ge. 2) then
               call prinf('jbox=*',jbox,1)
               call prin2('center1=*',center1,2)
               endif
               level1=box1(1)
               if( nterms(level0)+nterms(level1) .gt. 95 ) then
               call l2dmpmp(scale(level1),center1,
     1            rmlexp(iaddr(1,jbox)),nterms(level1),scale(level0),
     1            center0,mptemp,nterms(level0))
               else
               call l2dmpmp_carray(scale(level1),center1,
     1            rmlexp(iaddr(1,jbox)),nterms(level1),scale(level0),
     1            center0,mptemp,nterms(level0),carray,ldc)
               endif
               call l2dadd(mptemp,rmlexp(iaddr(1,ibox)),
     1            nterms(level0))
 2220       continue
            if (ifprint .ge. 2) then
            call prinf('=============*',x,0)
            endif
c       ... mark the local expansion of all kids and the parent
c
            endif
         endif
 2250    continue

C$OMP END TASK

C$OMP TASKWAIT

 2300    continue


c
c
ccc        call prinf('=== UPWARD PASS COMPLETE ===*',i,0)
c
c------------------------------------------------------------
c      DEBUGGING SEGMENT - once all multipole expansions are merged
c      to top level, one can compare it to the direct formation of the
c      expansion at the top level from the source locations.
c
ccc        call prinm(rmlexp(iaddr(1,1)),nterms(0))
c
ccc        call h2dformmp(ier,scale(0),source,charge,n,
ccc     1  	center,nterms(0),mptemp)
c
ccc        call prinm(mptemp,nterms(0))
c
ccc        call h2dmperr(rmlexp(iaddr(1,1)),mptemp,nterms(0),d)
ccc        call prin2('error in upward pass=*',d,1)
c
ccc        pause
ccc        stop
c      END DEBUGGING SEGMENT
c------------------------------------------------------------
c
         t2=second()
C$        t2=omp_get_wtime()
ccc        call prin2('time=*',t2-t1,1)
         timeinfo(3)=t2-t1






c
        if (ifprint .ge. 1) 
     $     call prinf('=== STEP 4 (mp to lo) ===*',i,0)
        t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 4, convert multipole expansions into the local ones
c
cc        call prinf('laddr=*',laddr,2*(nlev+1))
cc        call prin2('bsize=*',bsize,(nlev+1))
cc        do 4200 ibox=1,nboxes
ccc        ntops=0

        call l2dterms_list2(epsfmm, itable, ier)
c        call prinf('itable=*',itable,7*7)
c



        do 4500 ilev=3,nlev+1
c        t3=second()
cC$        t3=omp_get_wtime()


        do 4200 ichunk=1,laddr(2,ilev)/CHUNK_SIZE_M2L

C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ichunk,ilev)
C$OMP$PRIVATE(ibox_start, ibox_end, ier, ibox, box, center0, corners0)
C$OMP$PRIVATE(nkids, level0, radius, i, jbox, box1, center1, corners1)
C$OMP$PRIVATE(level1, mptemp, itype, list, nlist, ilist, nterms_trunc)
C$OMP$PRIVATE(ii,jj)

        ibox_start = (ichunk - 1) * CHUNK_SIZE_M2L + laddr(1,ilev)
        ibox_end = ibox_start + CHUNK_SIZE_M2L - 1


        do 4150 ibox = ibox_start, ibox_end


        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        if (ifprint .ge. 2) then
           call prinf('ibox=*',ibox,1)
           call prinf('box=*',box,15)
        endif
        level0=box(1)
        if (level0 .ge. 2) then
c
c       ... retrieve list #2
c
           itype=2
           call d2tgetl(ier,ibox,itype,list,nlist,wlists)
           if (ifprint .ge. 2) then
              call prinf('list2=*',list,nlist)
           endif
c
c       ... prune all sourceless boxes
c
c       ... for all pairs in list #2, apply the translation operator 
c
           do 4100 ilist=1,nlist
              jbox=list(ilist)
              call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
              if( box1(10) .eq. 0 ) goto 4100
              if (jbox.eq.0) goto 4100
              if ((box(12).eq.0).and.(ifprune_list2.eq.1))
     $           goto 4100
c
c       ... convert multipole expansions for all boxes in list 2 in local exp
c       ... if source is childless, evaluate directly (if cheaper)
c

              level1=box1(1)
c
              ifdirect2 = 0
c
              if_use_trunc = 0
c
              if (ifdirect2 .eq. 0) then
              if( if_use_trunc .eq. 0) then

                 call l2dzero(mptemp,nterms(level1))
                 if( nterms(level0)+nterms(level1) .gt. 95 ) then
                 call l2dmploc(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms(level1),
     $              scale(level0),
     1              center0,mptemp,nterms(level0))
                 else
                 call l2dmploc_carray(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms(level1),
     $              scale(level0),
     1              center0,mptemp,nterms(level0),
     $              carray,ldc)
                 endif
                 call l2dadd(mptemp,rmlexp(iaddr(2,ibox)),
     1              nterms(level0))


              else

              ii=box1(2)-box(2)
              jj=box1(3)-box(3)
              nterms_trunc=itable(ii,jj)
              nterms_trunc=min(nterms(level0),nterms_trunc)
              nterms_trunc=min(nterms(level1),nterms_trunc)

                 call l2dzero(mptemp,nterms_trunc)
                 if( nterms_trunc+nterms_trunc .gt. 95 ) then
                 call l2dmploc(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms_trunc,
     $              scale(level0),
     1              center0,mptemp,nterms_trunc)
                 else
                 call l2dmploc_carray(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms_trunc,
     $              scale(level0),
     1              center0,mptemp,nterms_trunc,
     $              carray,ldc)
                 endif
                 call l2dadd(mptemp,rmlexp(iaddr(2,ibox)),
     1              nterms_trunc)


              endif
              endif

 4100       continue
        endif

 4150   continue

C$OMP END TASK

 4200   continue


C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ilev)
C$OMP$PRIVATE(ibox_start2, ibox_end2, ier, ibox, box, center0, corners0)
C$OMP$PRIVATE(nkids, level0, radius, i, jbox, box1, center1, corners1)
C$OMP$PRIVATE(level1, mptemp, itype, list, nlist, ilist, nterms_trunc)
C$OMP$PRIVATE(ii,jj)
 

        ibox_start2 = laddr(2,ilev) / CHUNK_SIZE_M2L * CHUNK_SIZE_M2L
        ibox_start2 = ibox_start2 + laddr(1,ilev)
        ibox_end2 = laddr(1,ilev)+laddr(2,ilev)-1


        do 4350 ibox = ibox_start2, ibox_end2


        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        if (ifprint .ge. 2) then
           call prinf('ibox=*',ibox,1)
           call prinf('box=*',box,15)
        endif
        level0=box(1)
        if (level0 .ge. 2) then
c
c       ... retrieve list #2
c
           itype=2
           call d2tgetl(ier,ibox,itype,list,nlist,wlists)
           if (ifprint .ge. 2) then
              call prinf('list2=*',list,nlist)
           endif
c
c       ... prune all sourceless boxes
c
c       ... for all pairs in list #2, apply the translation operator 
c
           do 4300 ilist=1,nlist
              jbox=list(ilist)
              call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
              if( box1(10) .eq. 0 ) goto 4300
              if (jbox.eq.0) goto 4300
              if ((box(12).eq.0).and.(ifprune_list2.eq.1))
     $           goto 4300
c
c       ... convert multipole expansions for all boxes in list 2 in local exp
c       ... if source is childless, evaluate directly (if cheaper)
c

              level1=box1(1)
c
              ifdirect2 = 0
c
              if_use_trunc = 0
c
              if (ifdirect2 .eq. 0) then
              if( if_use_trunc .eq. 0) then

                 call l2dzero(mptemp,nterms(level1))
                 if( nterms(level0)+nterms(level1) .gt. 95 ) then
                 call l2dmploc(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms(level1),
     $              scale(level0),
     1              center0,mptemp,nterms(level0))
                 else
                 call l2dmploc_carray(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms(level1),
     $              scale(level0),
     1              center0,mptemp,nterms(level0),
     $              carray,ldc)
                 endif
                 call l2dadd(mptemp,rmlexp(iaddr(2,ibox)),
     1              nterms(level0))


              else

              ii=box1(2)-box(2)
              jj=box1(3)-box(3)
              nterms_trunc=itable(ii,jj)
              nterms_trunc=min(nterms(level0),nterms_trunc)
              nterms_trunc=min(nterms(level1),nterms_trunc)

                 call l2dzero(mptemp,nterms_trunc)
                 if( nterms_trunc+nterms_trunc .gt. 95 ) then
                 call l2dmploc(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms_trunc,
     $              scale(level0),
     1              center0,mptemp,nterms_trunc)
                 else
                 call l2dmploc_carray(scale(level1),center1,
     1              rmlexp(iaddr(1,jbox)),nterms_trunc,
     $              scale(level0),
     1              center0,mptemp,nterms_trunc,
     $              carray,ldc)
                 endif
                 call l2dadd(mptemp,rmlexp(iaddr(2,ibox)),
     1              nterms_trunc)


              endif
              endif

 4300       continue
        endif

 4350   continue


C$OMP END TASK




c        t4=second()
cC$        t4=omp_get_wtime()
c        write(*,*) 'level ', ilev, ' time in list2:', t4-t3
ccc        write(*,*) 'time in list2:', second()-t1
ccc        write(*,*) 'ntops:', ntops
ccc        write(*,*) 'speed:', ntops/(second()-t1)
 4500   continue




C$OMP TASKWAIT



c
        t2=second()
C$        t2=omp_get_wtime()
ccc     call prin2('time=*',t2-t1,1)
        timeinfo(4)=t2-t1
c       
        if (ifprint .ge. 1) 
     $     call prinf('=== STEP 5 (split lo) ===*',i,0)
        t1=second()
C$        t1=omp_get_wtime()
c
c       ... step 5, split all local expansions
c
ccc        do 5200 ibox=1,nboxes

        do 5500 ilev=3,nlev

        do 5200 ichunk=1,laddr(2,ilev)/CHUNK_SIZE_M2M

C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ichunk,ilev)
C$OMP$PRIVATE(ibox_start, ibox_end, ier, ibox, box, center0, corners0)
C$OMP$PRIVATE(nkids, level0, radius, i, jbox, box1, center1, corners1)
C$OMP$PRIVATE(level1, mptemp)

        ibox_start = (ichunk - 1) * CHUNK_SIZE_M2M + laddr(1,ilev)
        ibox_end = ibox_start + CHUNK_SIZE_M2M - 1
        
        do 5150 ibox = ibox_start, ibox_end
c
        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        call d2tnkids(box,nkids)
c       
        if (nkids .ne. 0) then
            level0=box(1)
            if (level0 .ge. 2) then
               if (ifprint .ge. 2) then
                  call prinf('ibox=*',ibox,1)
                  call prinf('box=*',box,15)
                  call prinf('nkids=*',nkids,1)
                  call prin2('center0=*',center0,2)
               endif
c
c       ... split local expansion of the parent box
c
               do 5100 i = 1,4
	          jbox = box(4+i)
	          if (jbox.eq.0) goto 5100
                  call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
                  radius = (corners1(1,1) - center1(1))**2
                  radius = radius + (corners1(2,1) - center1(2))**2
                  radius = sqrt(radius)
                  if (ifprint .ge. 2) then
                     call prinf('jbox=*',jbox,1)
                     call prin2('radius=*',radius,1)
                     call prin2('center1=*',center1,2)
                  endif
                  level1=box1(1)
                  if( nterms(level0)+nterms(level1) .gt. 95 ) then
                  call l2dlocloc(scale(level0),center0,
     1               rmlexp(iaddr(2,ibox)),nterms(level0),
     1               scale(level1),center1,mptemp,nterms(level1))
                  else
                  call l2dlocloc_carray(scale(level0),center0,
     1               rmlexp(iaddr(2,ibox)),nterms(level0),
     1               scale(level1),center1,mptemp,nterms(level1),
     1               carray,ldc)
                  endif
                  call l2dadd(mptemp,rmlexp(iaddr(2,jbox)),
     1   	       nterms(level1))
 5100          continue
               if (ifprint .ge. 2) call prinf('=============*',x,0)
            endif
        endif
c
        if (nkids .ne. 0) then
            level=box(1)
            if (level .ge. 2) then
               if( ifprint .ge. 2 ) then
                  call prinf('ibox=*',ibox,1)
                  call prinf('box=*',box,15)
                  call prinf('nkids=*',nkids,1)
               endif
            endif
        endif

 5150   continue

C$OMP END TASK

 5200   continue



C$OMP TASK DEFAULT(SHARED)
C$OMP$FIRSTPRIVATE(ilev)
C$OMP$PRIVATE(ibox_start2, ibox_end2, ier, ibox, box, center0, corners0)
C$OMP$PRIVATE(nkids, level0, radius, i, jbox, box1, center1, corners1)
C$OMP$PRIVATE(level1, mptemp)


        ibox_start2 = laddr(2,ilev) / CHUNK_SIZE_M2M * CHUNK_SIZE_M2M
        ibox_start2 = ibox_start2 + laddr(1,ilev)
        ibox_end2 = laddr(1,ilev)+laddr(2,ilev)-1

        
        do 5450 ibox = ibox_start2, ibox_end2
c
        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        call d2tnkids(box,nkids)
c       
        if (nkids .ne. 0) then
            level0=box(1)
            if (level0 .ge. 2) then
               if (ifprint .ge. 2) then
                  call prinf('ibox=*',ibox,1)
                  call prinf('box=*',box,15)
                  call prinf('nkids=*',nkids,1)
                  call prin2('center0=*',center0,2)
               endif
c
c       ... split local expansion of the parent box
c
               do 5300 i = 1,4
	          jbox = box(4+i)
	          if (jbox.eq.0) goto 5300
                  call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
                  radius = (corners1(1,1) - center1(1))**2
                  radius = radius + (corners1(2,1) - center1(2))**2
                  radius = sqrt(radius)
                  if (ifprint .ge. 2) then
                     call prinf('jbox=*',jbox,1)
                     call prin2('radius=*',radius,1)
                     call prin2('center1=*',center1,2)
                  endif
                  level1=box1(1)
                  if( nterms(level0)+nterms(level1) .gt. 95 ) then
                  call l2dlocloc(scale(level0),center0,
     1               rmlexp(iaddr(2,ibox)),nterms(level0),
     1               scale(level1),center1,mptemp,nterms(level1))
                  else
                  call l2dlocloc_carray(scale(level0),center0,
     1               rmlexp(iaddr(2,ibox)),nterms(level0),
     1               scale(level1),center1,mptemp,nterms(level1),
     1               carray,ldc)
                  endif
                  call l2dadd(mptemp,rmlexp(iaddr(2,jbox)),
     1   	       nterms(level1))
 5300          continue
               if (ifprint .ge. 2) call prinf('=============*',x,0)
            endif
        endif
c
        if (nkids .ne. 0) then
            level=box(1)
            if (level .ge. 2) then
               if( ifprint .ge. 2 ) then
                  call prinf('ibox=*',ibox,1)
                  call prinf('box=*',box,15)
                  call prinf('nkids=*',nkids,1)
               endif
            endif
        endif

 5450   continue

C$OMP END TASK

C$OMP TASKWAIT

 5500   continue



        t2=second()
C$        t2=omp_get_wtime()
ccc     call prin2('time=*',t2-t1,1)
        timeinfo(5)=t2-t1


C$OMP END SECTIONS

C$OMP END PARALLEL

ccccc      tt(2) = second()
ccccc      call prin2('Time in ')


        return
        end
















c
c
c
c
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c        this is the end of the debugging code and the beginning 
c        of the auxiliary routines
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c
c
c
c
        subroutine l2dpsort(n,isource,psort,pot)
        implicit real *8 (a-h,o-z)
        integer isource(*)
        complex *16 pot(*),psort(*)
c
ccc        call prinf('isource=*',isource,n)
c
C$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(i)
        do i=1,n
        pot(isource(i))=psort(i)
        enddo
C$OMP END PARALLEL DO
c
        return
        end
c
c
c
c
c
        subroutine l2dfsort(n,isource,fldsort,fld)
        implicit real *8 (a-h,o-z)
        integer isource(*)
        complex *16 fld(2,*),fldsort(2,*)
c        
ccc        call prinf('isource=*',isource,n)
c
C$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(i)
        do i=1,n
        fld(1,isource(i))=fldsort(1,i)
        fld(2,isource(i))=fldsort(2,i)
        enddo
C$OMP END PARALLEL DO
c
        return
        end
c
c
c
c
c
        subroutine l2dhsort(n,isource,hesssort,hess)
        implicit real *8 (a-h,o-z)
        integer isource(*)
        complex *16 hess(3,*),hesssort(3,*)
c        
ccc        call prinf('isource=*',isource,n)
c
C$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(i)
        do i=1,n
        hess(1,isource(i))=hesssort(1,i)
        hess(2,isource(i))=hesssort(2,i)
        hess(3,isource(i))=hesssort(3,i)
        enddo
C$OMP END PARALLEL DO
c
        return
        end
c
c
c
c
c
        subroutine l2dreorder(nsource,source,
     $     ifcharge,charge,isource,ifdipole,
     1     dipstr,dipvec,sourcesort,chargesort,dipvecsort,dipstrsort) 
        implicit real *8 (a-h,o-z)
        real *8 source(2,*),sourcesort(2,*)
        integer isource(*)
        real *8 dipvec(2,*),dipvecsort(2,*)
        complex *16 charge(*),chargesort(*),dipstr(*),dipstrsort(*)
c       
ccc        call prinf('nsource=*',nsource,1)
C$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(i)
        do i = 1,nsource
        sourcesort(1,i) = source(1,isource(i))
        sourcesort(2,i) = source(2,isource(i))
        if( ifcharge .ge. 1 ) then
        chargesort(i) = charge(isource(i))
        endif
        if (ifdipole .ge. 1) then
        dipstrsort(i) = dipstr(isource(i))
        dipvecsort(1,i) = dipvec(1,isource(i))
        dipvecsort(2,i) = dipvec(2,isource(i))
        endif
        enddo
C$OMP END PARALLEL DO
        return
        end
c
c
c
c
c
        subroutine l2dreordertarg(ntarget,target,itarget,targetsort)
        implicit real *8 (a-h,o-z)
        real *8 target(2,*),targetsort(2,*)
        integer itarget(*)
c       
ccc        call prinf('ntarget=*',ntarget,1)
C$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(i)
        do i = 1,ntarget
        targetsort(1,i) = target(1,itarget(i))
        targetsort(2,i) = target(2,itarget(i))
        enddo
C$OMP END PARALLEL DO
        return
        end
c
c
c
c
c
        subroutine l2dzero(mpole,nterms)
        implicit real *8 (a-h,o-z)
c
c       ... set multipole to zero
c
        complex *16 mpole(0:nterms)
c       
        do n=0,nterms
        mpole(n)=0
        enddo
c
        return
        end
c
c
c
c
c
        subroutine l2dadd(mpole,mpole2,nterms)
        implicit real *8 (a-h,o-z)
        complex *16 mpole(0:nterms)
        complex *16 mpole2(0:nterms)
c       
        do n=0,nterms
        mpole2(n)=mpole2(n)+mpole(n)
        enddo
c
        return
        end
c
c
c
c
c
        subroutine l2dmpalloc(wlists,iaddr,nboxes,lmptot,nterms)
        implicit real *8 (a-h,o-z)
        integer box(20)
        integer nterms(0:*)
        integer iaddr(2,nboxes)
        real *8 center0(2),corners0(2,4)
        real *8 wlists(*)
c
c       ... construct pointer array iaddr for addressing multipole and
c       local expansion
c
        iptr=1
        do ibox=1,nboxes
        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        level=box(1)
c
c       ... first, allocate memory for the multipole expansion
c       
        iaddr(1,ibox)=iptr
        iptr=iptr+(nterms(level)+1)*2
c
c       ... then, allocate memory for the local expansion
c       
        iaddr(2,ibox)=iptr
        iptr=iptr+(nterms(level)+1)*2
c       
        enddo
        lmptot = iptr
        return
        end
c
c
c
c
c
        subroutine l2d_init_carray(carray,ldc)
        implicit real *8 (a-h,o-z)
        real *8 carray(0:ldc,0:ldc)

        do l = 0,ldc
        carray(l,0) = 1.0d0
        enddo
        do m=1,ldc
        carray(m,m) = 1.0d0
        do l=m+1,ldc
            carray(l,m)=carray(l-1,m)+carray(l-1,m-1)
        enddo
        enddo
c
        return
        end
        




c=============================================================================
c     SUNLI:  This is the end of auxiliary routines and beginning of
c             subroutine for task-based parallel model. 
c
c=============================================================================


      subroutine P2T_task
     $    (ibox_start, CHUNK_SIZE_P2T,
     $     wlists,
     $     sourcesort, ifcharge,chargesort,ifdipole,dipstrsort,
     $     ifpot,pot,ifgrad,grad,ifhess,hess,
     $     targetsort,ifpottarg,pottarg,ifgradtarg,gradtarg,
     $     ifhesstarg,hesstarg)

        implicit real *8 (a-h,o-z)
c
c
        integer ibox_start, CHUNK_SIZE_P2T

        real *8 wlists(*)

        real *8 sourcesort(2,*)
        complex *16 chargesort(*),dipstrsort(*)
        real *8 targetsort(2,*)
c
        complex *16 pot(*),grad(*),hess(*)
        complex *16 pottarg(*),gradtarg(*),hesstarg(*)


        complex *16 ptemp,gtemp,htemp
        integer list(10 000)
        real *8 center0(2),corners0(2,4)
        real *8 center1(2),corners1(2,4)        
        integer box(15),box1(15)

c 
        ifprint = 0

        ibox_end = ibox_start + CHUNK_SIZE_P2T - 1

        do ibox2 = ibox_start, ibox_end

        call d2tgetb(ier,ibox2,box,center0,corners0,wlists)
        call d2tnkids(box,nkids)
c
        if (ifprint .ge. 2) then
           call prinf('ibox2=*',ibox2,1)
           call prinf('box=*',box,15)
           call prinf('nkids=*',nkids,1)
        endif
c
        if (nkids .eq. 0) then
            npts=box(10)
            if (ifprint .ge. 2) then
               call prinf('npts=*',npts,1)
               call prinf('isource=*',isource(box(9)),box(10))
            endif
        endif
c
c
        if (nkids .eq. 0) then
c
c       ... evaluate self interactions
c
        call cfmm2dpart_direct_self_sym(box,sourcesort,
     $     ifcharge,chargesort,ifdipole,dipstrsort,
     $     ifpot,pot,ifgrad,grad,ifhess,hess,
     $     targetsort,ifpottarg,pottarg,ifgradtarg,gradtarg,
     $     ifhesstarg,hesstarg)
c
c
c       ... retrieve list #1
c
c       ... evaluate interactions with the nearest neighbours
c
        itype=1
        call d2tgetl(ier,ibox2,itype,list,nlist,wlists)
        if (ifprint .ge. 2) call prinf('list1=*',list,nlist)
c
c       ... for all pairs in list #1, 
c       evaluate the potentials and gradients directly
c
            do ilist=1,nlist
               jbox=list(ilist)
               call d2tgetb(ier,jbox,box1,center1,corners1,wlists)
c
c       ... prune all sourceless boxes
c
         if( box1(10) .ne. 0 )
     $      call cfmm2dpart_direct(box1,box,sourcesort,
     $         ifcharge,chargesort,ifdipole,dipstrsort,
     $         ifpot,pot,ifgrad,grad,ifhess,hess,
     $         targetsort,ifpottarg,pottarg,ifgradtarg,gradtarg,
     $         ifhesstarg,hesstarg)
c
          enddo !ilist
        endif


      



      enddo !ibox2


      return
      end


      subroutine P2M_task
     $    (ibox_start, CHUNK_SIZE_P2M,
     $     wlists,
     $     sourcesort, ifcharge,chargesort,ifdipole,dipstrsort,
     $     rmlexp, scale, mptemp, lmptemp, iaddr, nterms)



        implicit real *8 (a-h,o-z)
c
c
        integer ibox_start, CHUNK_SIZE_P2M

        real *8 wlists(*)

        real *8 sourcesort(2,*)
        complex *16 chargesort(*),dipstrsort(*)
c
        real *8 center0(2),corners0(2,4)
        integer box(15)

        integer level, lmptemp
        real *8 radius
        real *8 rmlexp(*), scale(0:*), mptemp(lmptemp)
        integer iaddr(2,*), nterms(0:*)


        ifprint = 0

        ibox_end = ibox_start + CHUNK_SIZE_P2M - 1

        do ibox = ibox_start, ibox_end


c          print *, "inside ibox loop"

        call d2tgetb(ier,ibox,box,center0,corners0,wlists)
        call d2tnkids(box,nkids)
c
        level=box(1)
        if( level .lt. 2 ) goto 9200
c          print *, "level > 2"
c
c
        if (ifprint .ge. 2) then
           call prinf('ibox=*',ibox,1)
           call prinf('box=*',box,15)
           call prinf('nkids=*',nkids,1)
        endif
c
        if (nkids .eq. 0) then
c        ipts=box(9)
c        npts=box(10)
c        call prinf('ipts=*',ipts,1)
c        call prinf('npts=*',npts,1)
        npts=box(10)
        if (ifprint .ge. 2) then
           call prinf('npts=*',npts,1)
           call prinf('isource=*',isource(box(9)),box(10))
        endif
        endif
c
c       ... prune all sourceless boxes
c
        if( box(10) .eq. 0 ) goto 9200
c
        if (nkids .eq. 0) then
c
c       ... form multipole expansions
c
	    radius = (corners0(1,1) - center0(1))**2
	    radius = radius + (corners0(2,1) - center0(2))**2
	    radius = sqrt(radius)
c
            call l2dzero(rmlexp(iaddr(1,ibox)),nterms(level))
            if_use_trunc = 0

            if( ifcharge .eq. 1 ) then
            call l2dformmp(ier,scale(level),sourcesort(1,box(9)),
     1  	chargesort(box(9)),npts,center0,nterms(level),
     2          rmlexp(iaddr(1,ibox)))        
            endif
c 
c               call prin2('after formmp, rmlexp=*',
c     $            rmlexp(iaddr(1,ibox)),2*(2*nterms(level)+1))
c
            if (ifdipole .eq. 1 ) then
               call l2dzero(mptemp,nterms(level))
               call l2dformmp_dp(ier,scale(level),
     $           sourcesort(1,box(9)),
     1           dipstrsort(box(9)),
     $           npts,center0,nterms(level),
     2           mptemp)
              call l2dadd(mptemp,rmlexp(iaddr(1,ibox)),nterms(level))
            endif
         endif
c
 9200    continue

        enddo !ibox
c        call prin2('rmlexp = ',
c     $    rmlexp(iaddr(1,ibox_start)),nterms(level))
      

        return

        end
