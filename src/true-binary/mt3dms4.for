C
C%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
C                                                                      %
C                               MT3DMS                                 %
C      a modular three-dimensional multi-species transport model       %
C    for simulation of advection, dispersion and chemical reactions    %
C                of contaminants in groundwater systems                %
C                                                                      %
C                  For Technical Information Contact                   %
C                           Chunmiao Zheng                             %
C                  Department of Geological Sciences                   %
C                        University of Alabama                         %
C                        Tuscaloosa, AL 35487                          %
C                        Email: czheng@ua.edu                          %
C              Web site: http://hydro.geo.ua.edu/mt3d                  %
C                                                                      %
C%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
C
C MT3DMS is based on MT3D originally developed by Chunmiao Zheng
C at S.S. Papadopulos & Associates, Inc. and documented for
C the United States Environmental Protection Agency.
C MT3DMS is written by Chunmiao Zheng and P. Patrick Wang
C with the iterative solver routine by Tsun-Zee Mai.
C Funding for MT3DMS development is provided, in part, by
C U.S. Army Corps of Engineers, Research and Development Center.
C
C Copyright, 1998-2003, The University of Alabama. All rights reserved.
C
C This program is provided without any warranty.
C No author or distributor accepts any responsibility
C to anyone for the consequences of using it
C or for whether it serves any particular purpose.
C The program may be copied, modified and redistributed,
C but ONLY under the condition that the above copyright notice
C and this notice remain intact.
C
C=======================================================================
C Version history: 06-23-1998 (3.00.A)
C                  05-10-1999 (3.00.B)
C                  11-15-1999 (3.50.A)
C                  08-15-2000 (3.50.B)
C                  08-12-2001 (4.00)
C                  05-27-2003 (4.50)
C
C--SET MAXIMUM ARRAY DIMENSIONS AND FORTRAN UNIT NUMBERS FOR I/O FILES.
C--MXPRS:  MAXIMUM NUMBER OF TIMES AT WHICH RESULTS ARE SAVED;
C--MXSTP:  MAXIMUM NUMBER OF TIME STEPS IN FLOW MODEL;
C--MXOBS:  MAXIMUM NUMBER OF OBSERVATION POINTS;
C--MXCOMP: MAXMUM NUMBER OF COMPONENTS.
C  =====================================================================
C
      IMPLICIT  NONE
      INTEGER,PARAMETER :: MXPRS=1000,MXSTP=1000,MXOBS=1000,MXCOMP=100
      INTEGER,PARAMETER :: INBTN=1,INADV=2,INDSP=3,INSSM=4,INRCT=8,
     &                     INGCG=9,INUHF=10
      INTEGER,PARAMETER :: IOUT=16,ICNF=17,IUCN=200,IUCN2=300,
     &                     IOBS=400,IMAS=600,ICBM=800
      INTEGER   IX,ISUMX,ISUMIX,ISUM,ISUM2,NCOL,NROW,NLAY,NCOMP,MCOMP,
     &          LCLAYC,LCDELR,LCDELC,LCDZ,LCPR,LCXBC,LCYBC,LCZBC,LCQX,
     &          LCQY,LCQZ,LCDH,LCIB,LCCOLD,LCCNEW,LCCADV,LCRETA,LCBUFF,
     &          MIXELM,MXPART,LCXP,LCYP,LCZP,LCCNPT,LCCHEK,
     &          NCOUNT,NPINS,NRC,LCAL,LCTRPT,LCTRPV,LCDM,LCDXX,LCDXY,
     &          LCDXZ,LCDYX,LCDYY,LCDYZ,LCDZX,LCDZY,LCDZZ,LCSSMC,
     &          LCIRCH,LCRECH,LCCRCH,LCIEVT,LCEVTR,LCCEVT,MXSS,LCSS,
     &          ISOTHM,IREACT,LCRHOB,LCPRSITY2,LCFRAC,LCRETA2,
     &          LCSP1,LCSP2,LCRC1,LCRC2,INTERP,
     &          ISEED,ITRACK,NPL,NPH,NPMIN,NPMAX,NPLANE,NLSINK,NPSINK,
     &          NPRS,NOBS,LOCOBS,NSS,KSTP,KPER,NTSS,I,N,NPS,
     &          IFMTCN,IFMTNP,IFMTRF,IFMTDP,MXSTRN,
     &          NPER,NSTP,ISTAT,LCQSTO,LCHTOP,LCCWGT,LCSR,
     &          LCINDX,LCINDY,LCINDZ,ISS,IVER,NPROBS,NPRMAS,IRCTOP,
     &          MXITER,IPRGCG,NADVFD,ITP,NODES,ICNVG,ITER1,ITO,
     &          ISOLVE,LCA,LCQ,LCWK,LCCNCG,LCLRCH,LCRHS,
     &          IMPSOL,NCRS,ISPD,IGETSC,L,INDEX,ICOMP,NPERFL,IERR,
     &          iNameFile,iflen,ic,iFTLfmt
      REAL      X,TIMPRS,TSLNGH,PERCEL,HORIGN,XMAX,YMAX,ZMAX,CINACT,
     &          TMASIO,RMASIO,DCEPS,SRMULT,WD,DCHMOC,HT1,HT2,TIME1,
     &          TIME2,DT0,DELT,DTRACK,DTDISP,DTRANS,THKMIN,
     &          DTSSM,DTRCT,DTRACK2,RFMIN,TMASS,ACCL,CCLOSE,
     &          TTSMULT,TTSMAX,TMASIN,TMASOT,ERROR,ERROR2,
     &          start_time,end_time,total_time
      LOGICAL   TRNOP(10),UNIDX,UNIDY,UNIDZ,SAVUCN,SAVCBM,CHKMAS,
     &          FWEL,FDRN,FRCH,FEVT,FRIV,FGHB,PRTOUT,UPDLHS,EXISTED,
     &          FSTR,FRES,FFHB,FIBS,FTLK,FLAK,FMAW,FDRT,FETS,FUSR(3)
      CHARACTER FLNAME*50,FINDEX*30,TUNIT*4,LUNIT*4,MUNIT*4,FPRT*1
      DIMENSION X(:),IX(:),
     &          TIMPRS(MXPRS),TSLNGH(MXSTP),LOCOBS(3,MXOBS),
     &          NCOUNT(MXCOMP),NPINS(MXCOMP),NRC(MXCOMP),
     &          TMASIO(122,2,MXCOMP),RMASIO(122,2,MXCOMP),
     &          TMASS(4,3,MXCOMP),TMASIN(MXCOMP),TMASOT(MXCOMP),
     &          ERROR(MXCOMP),ERROR2(MXCOMP)
      ALLOCATABLE :: X,IX
      COMMON   /PD/HORIGN,XMAX,YMAX,ZMAX,UNIDX,UNIDY,UNIDZ
      COMMON   /FC/FWEL,FDRN,FRCH,FEVT,FRIV,FGHB,
     &          FSTR,FRES,FFHB,FIBS,FTLK,FLAK,FMAW,FDRT,FETS,FUSR
      COMMON   /OC/IFMTCN,IFMTNP,IFMTRF,IFMTDP,SAVUCN,
     &             SAVCBM,CHKMAS,NPRMAS
      COMMON   /AD/PERCEL,ITRACK,WD,ISEED,DCEPS,NPLANE,NPL,NPH,
     &             NPMIN,NPMAX,SRMULT,INTERP,NLSINK,NPSINK,DCHMOC
      COMMON   /GCGIDX/L(19)
      COMMON   /FTL/iFTLfmt
C
C--Get CPU time at the start of simulation
      Call CPU_TIME(start_time)
C
C--WRITE AN IDENTIFIER TO SCREEN
      WRITE(*,101)
  101 FORMAT(1X,'MT3DMS - Modular 3-D Multi-Species Transport Model',
     & ' [Version 4.50]',
     & /1X,'Developed at University of Alabama',
     & ' for U.S. Department of Defense'/)
C
C--INITIALIZE CHARACTER VARIABLES
      FLNAME=' '
      FPRT=' '
C
C--The following statement should be uncommented in order to use
C--GETCL to retrieve a command line argument.  The call to GETCL may
C--be commented out for compilers that do not support it.
      IF(FLNAME.EQ.' ') CALL GETCL(FLNAME)
C
C--Get Name of NAME File from Screen
      IF(FLNAME.EQ.' ') THEN
        write(*,102)
  102   format(1x,'Enter Name of the MT3DMS NAME File: ')
        read(*,'(a)') flname
      ENDIF
C
C--If NAME FILE is not given, open files using the original method
C--prior to Version 4.
      IF(FLNAME.eq.' ') THEN
        iNameFile=0
C
C--otherwise open files using the same method as in MODFLOW-2000
      ELSE
        iflen=index(flname,' ')-1
        inquire(file=flname(1:iflen),exist=existed)
        if(.not.existed) then
          flname=flname(1:iflen)//'.nam'
          inquire(file=flname(1:iflen+4),exist=existed)
          if(.not.existed) then
            write(*,103) flname(1:iflen),flname(1:iflen+4)
            stop
          endif
        endif
  103   format(1x,'Error: Specified Name file does not exist: ',
     &   a,' or ',a)
        Write(*,104) FLNAME
  104   Format(1x,'Using NAME File: ',a)
        iNameFile=99
        Open(iNameFile,file=flname,status='old')
        Call NameFile(iNameFile,TRNOP,IOUT,INBTN,
     &   INADV,INDSP,INSSM,INRCT,INGCG,INUHF,FPRT)
        Close (iNameFile)
      ENDIF
C
C--OPEN STANDARD OUTPUT AND BASIC INPUT FILES
      IF(iNameFile.eq.0) THEN
C
      FINDEX='Standard Output File: '
      ISTAT=0
      CALL OPENFL(IOUT,ISTAT,FLNAME,0,FINDEX)
C
      FINDEX='Basic Transport Input File: '
      ISTAT=1
      CALL OPENFL(INBTN,ISTAT,FLNAME,0,FINDEX)
C
      ENDIF
C
C--WRITE PROGRAM TITLE TO OUTPUT FILE
      WRITE(IOUT,11)
   11 FORMAT(/30X,71('+')/30X,'+',69X,'+'
     &  /30X,'+',28X,'   MT3DMS',32X,'+'
     &  /30X,'+',13X,'A Modular 3D Multi-Species Transport Model ',
     &           13X,'+'
     &  /30X,'+', 4X,'For Simulation of Advection, Dispersion and',
     &           ' Chemical Reactions',3X,'+'
     &  /30X,'+',16X,'of Contaminants in Groundwater Systems',15X,'+'
     &  /30X,'+',69X,'+'/30X,71('+')/)
C
C--DEFINE PROBLEM DIMENSION AND SIMULATION OPTIONS
      CALL BTN4DF(INBTN,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,NPER,
     & NCOMP,MCOMP,TRNOP,TUNIT,LUNIT,MUNIT,NODES,MXCOMP,iNameFile)
C
C--OPEN INPUT FILES FOR THE VARIOUS TRASNPORT OPTIONS
      IF(iNameFile.ne.0) goto 105
C
      IF(TRNOP(1)) THEN
        FINDEX='Advection Input File: '
        ISTAT=1
        CALL OPENFL(INADV,ISTAT,FLNAME,0,FINDEX)
      ENDIF
      IF(TRNOP(2)) THEN
        FINDEX='Dispersion Input File: '
        ISTAT=1
        CALL OPENFL(INDSP,ISTAT,FLNAME,0,FINDEX)
      ENDIF
      IF(TRNOP(3)) THEN
        FINDEX='Sink & Source Input File: '
        ISTAT=1
        CALL OPENFL(INSSM,ISTAT,FLNAME,0,FINDEX)
      ENDIF
      IF(TRNOP(4)) THEN
        FINDEX='Chemical Reaction Input File: '
        ISTAT=1
        CALL OPENFL(INRCT,ISTAT,FLNAME,0,FINDEX)
      ENDIF
      IF(TRNOP(5)) THEN
        FINDEX='GCG Solver Input File: '
        ISTAT=1
        CALL OPENFL(INGCG,ISTAT,FLNAME,0,FINDEX)
      ENDIF
C
C--OPEN UNFORMATTED HEAD & FLOW FILE SAVED BY A FLOW MODEL
      FINDEX='Flow-Transport Link File: '
      ISTAT=1
      iFTLfmt=0
      CALL OPENFL(-INUHF,ISTAT,FLNAME,0,FINDEX)
      WRITE(*,15)
   15 FORMAT(1X,'Print Contents of Flow-Transport Link File',
     & ' for Checking (y/n)? ')
      READ(*,'(A1)') FPRT
  105 IF(FPRT.EQ.' ') FPRT='N'
C
C--ALLOCATE STORAGE SPACE FOR DATA ARRAYS
      CALL BTN4AL(INBTN,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,NCOMP,
     & LCLAYC,LCDELR,LCDELC,LCHTOP,LCDZ,LCPR,LCXBC,LCYBC,LCZBC,
     & LCQX,LCQY,LCQZ,LCQSTO,LCDH,LCIB,LCCOLD,LCCNEW,LCCWGT,
     & LCCADV,LCRETA,LCSR,LCBUFF,ISOTHM,LCRHOB,LCPRSITY2,LCRETA2)
C
      CALL FMI4AL(INUHF,IOUT,TRNOP,NPERFL,ISS,IVER)
C
      IF(TRNOP(1)) CALL ADV4AL(INADV,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,
     & MCOMP,MIXELM,MXPART,PERCEL,NADVFD,LCXP,LCYP,LCZP,
     & LCINDX,LCINDY,LCINDZ,LCCNPT,LCCHEK,TRNOP)
C
      IF(TRNOP(2)) CALL DSP4AL(INDSP,IOUT,ISUM,ISUM2,
     & NCOL,NROW,NLAY,LCAL,LCTRPT,LCTRPV,LCDM,LCDXX,LCDXY,LCDXZ,
     & LCDYX,LCDYY,LCDYZ,LCDZX,LCDZY,LCDZZ)
C
      IF(TRNOP(3)) CALL SSM4AL(INSSM,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,
     & NCOMP,LCIRCH,LCRECH,LCCRCH,LCIEVT,LCEVTR,LCCEVT,MXSS,LCSS,
     & IVER,LCSSMC)
C
      IF(TRNOP(4)) CALL RCT4AL(INRCT,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,
     & NCOMP,ISOTHM,IREACT,IRCTOP,IGETSC,LCRHOB,LCPRSITY2,LCRETA2,
     & LCFRAC,LCSP1,LCSP2,LCRC1,LCRC2)
C
      IF(TRNOP(5)) CALL GCG4AL(INGCG,IOUT,ISUM,ISUM2,NCOL,NROW,NLAY,
     & MXITER,ITER1,NCRS,ISOLVE,LCA,LCQ,LCWK,LCCNCG,LCLRCH,LCRHS)
C
C--CHECK WHETHER ARRAYS X AND IX ARE DIMENSIONED LARGE ENOUGH.
C--IF NOT STOP
      ISUMX=ISUM
      ISUMIX=ISUM2
      WRITE(IOUT,20) ISUMX,ISUMIX
   20 FORMAT(1X,42('.')/1X,'ELEMENTS OF THE  X ARRAY USED =',I10,
     & /1X,'ELEMENTS OF THE IX ARRAY USED =',I10,
     & /1X,42('.')/)
C
      ALLOCATE (X(0:ISUMX),IX(0:ISUMIX),STAT=IERR)
      IF(IERR.NE.0) THEN
        WRITE(*,*) 'STOP.  NOT ENOUGH MEMORY'
        STOP
      ENDIF
C
C--INITIALIZE VARIABLES.
      IMPSOL=0
      IF(TRNOP(5)) THEN
        IMPSOL=1
        ISPD=1
        IF(MIXELM.EQ.0) ISPD=0
      ENDIF
C
C--INITILIZE ARRAYS.
      DO I=1,ISUMX
        X(I)=0.
      ENDDO
      DO I=1,ISUMIX
        IX(I)=0
      ENDDO
      DO IC=1,NCOMP
        DO I=1,122
          TMASIO(I,1,IC)=0.
          TMASIO(I,2,IC)=0.
        ENDDO
        DO I=1,4
          TMASS(I,1,IC)=0.
          TMASS(I,2,IC)=0.
          TMASS(I,3,IC)=0.
        ENDDO
      ENDDO
C
C--READ AND PREPARE INPUT DATA RELEVANT TO
C--THE ENTIRE SIMULATION
      CALL BTN4RP(INBTN,IOUT,IUCN,IUCN2,IOBS,IMAS,ICNF,ICBM,
     & NCOL,NROW,NLAY,NCOMP,ISOTHM,IX(LCLAYC),X(LCDELR),X(LCDELC),
     & X(LCHTOP),X(LCDZ),X(LCPR),IX(LCIB),X(LCCOLD),X(LCCNEW),
     & X(LCCADV),CINACT,THKMIN,X(LCXBC),X(LCYBC),X(LCZBC),
     & X(LCRETA),RFMIN,X(LCBUFF),MXPRS,NPRS,TIMPRS,
     & MXOBS,NOBS,NPROBS,LOCOBS,TUNIT,LUNIT,MUNIT)
C
      IF(TRNOP(1)) CALL ADV4RP(INADV,IOUT,NCOL,NROW,NLAY,MCOMP,
     & MIXELM,MXPART,NADVFD,NCOUNT)
C
      IF(TRNOP(2)) CALL DSP4RP(INDSP,IOUT,NCOL,NROW,NLAY,
     & X(LCAL),X(LCTRPT),X(LCTRPV),X(LCDM))
C
      IF(TRNOP(4)) CALL RCT4RP(INRCT,IOUT,NCOL,NROW,NLAY,NCOMP,IX(LCIB),
     & X(LCCOLD),X(LCPR),ISOTHM,IREACT,IRCTOP,IGETSC,X(LCRHOB),X(LCSP1),
     & X(LCSP2),X(LCSR),X(LCRC1),X(LCRC2),X(LCRETA),X(LCBUFF),
     & X(LCPRSITY2),X(LCRETA2),X(LCFRAC),RFMIN,IFMTRF,DTRCT)
C
      IF(TRNOP(5)) CALL GCG4RP(INGCG,IOUT,MXITER,ITER1,ISOLVE,ACCL,
     & CCLOSE,IPRGCG)
C
C--FOR EACH STRESS PERIOD***********************************************
      HT1=0.
      HT2=0.
      DTRANS=0.
      NPS=1
      DO KPER=1,NPER
C
C--WRITE AN INDENTIFYING MESSAGE
      WRITE(*,50) KPER
      WRITE(IOUT,51) KPER
      WRITE(IOUT,'(1X)')
   50 FORMAT(/1X,'STRESS PERIOD NO.',I5)
   51 FORMAT(//35X,62('+')/55X,'STRESS PERIOD NO.',I5.3/35X,62('+'))
C
C--GET STRESS TIMING INFORMATION
      CALL BTN4ST(INBTN,IOUT,NSTP,MXSTP,TSLNGH,DT0,MXSTRN,TTSMULT,
     & TTSMAX,TUNIT)
C
C--READ AND PREPARE INPUT INFORMATION WHICH IS CONSTANT
C--WITHIN EACH STRESS PERIOD
      IF(TRNOP(3)) CALL SSM4RP(INSSM,IOUT,KPER,NCOL,NROW,NLAY,NCOMP,
     & IX(LCIB),X(LCCNEW),X(LCCRCH),X(LCCEVT),MXSS,NSS,X(LCSS),
     & X(LCSSMC))
C
C--FOR EACH FLOW TIME STEP----------------------------------------------
      DO KSTP=1,NSTP
      DELT=TSLNGH(KSTP)
      HT1=HT2
      HT2=HT2+DELT
C
C--WRITE AN INDENTIFYING MESSAGE
      WRITE(*,60) KSTP,HT1,HT2
      WRITE(IOUT,61) KSTP,HT1,HT2
      WRITE(IOUT,'(1X)')
   60 FORMAT(/1X,'TIME STEP NO.',I5
     & /1X,'FROM TIME =',G13.5,' TO ',G13.5/)
   61 FORMAT(//42X,48('=')/57X,'TIME STEP NO.',I5.3/42X,48('=')
     & //1X,'FROM TIME =',G13.5,' TO ',G13.5)
C
C--READ AND PROCESS SATURATED THICKNESS, VELOCITY COMPONENTS
C--ACROSS CELL INTERFACES, AND SINK/SOURCE INFORMATION
C--(NOTE THAT THESE ITEMS ARE READ ONLY ONCE IF FLOW MODEL
C--IS STEADY-STATE AND HAS SINGLE STRESS PERIOD)
      IF(KPER*KSTP.GT.1.AND.ISS.NE.0.AND.NPERFL.EQ.1) GOTO 70
C
      CALL FMI4RP1(INUHF,IOUT,KPER,KSTP,NCOL,NROW,NLAY,NCOMP,FPRT,
     & IX(LCLAYC),IX(LCIB),HORIGN,X(LCDH),X(LCPR),X(LCDELR),X(LCDELC),
     & X(LCDZ),X(LCXBC),X(LCYBC),X(LCZBC),X(LCQSTO),X(LCCOLD),
     & X(LCCNEW),X(LCRETA),X(LCQX),X(LCQY),X(LCQZ),
     & DTRACK,DTRACK2,THKMIN,ISS,IVER)
C
      IF(TRNOP(3)) CALL FMI4RP2(INUHF,IOUT,KPER,KSTP,NCOL,NROW,NLAY,
     & NCOMP,FPRT,IX(LCLAYC),IX(LCIB),X(LCDH),X(LCPR),X(LCDELR),
     & X(LCDELC),IX(LCIRCH),X(LCRECH),IX(LCIEVT),X(LCEVTR),
     & MXSS,NSS,NTSS,X(LCSS),X(LCBUFF),DTSSM)
C
C--CALCULATE COEFFICIENTS THAT VARY WITH FLOW-MODEL TIME STEP
      IF(TRNOP(2)) CALL DSP4CF(IOUT,KSTP,KPER,NCOL,NROW,NLAY,
     & IX(LCIB),X(LCPR),X(LCDELR),X(LCDELC),X(LCDH),
     & X(LCQX),X(LCQY),X(LCQZ),X(LCAL),X(LCTRPT),X(LCTRPV),X(LCDM),
     & DTDISP,X(LCDXX),X(LCDXY),X(LCDXZ),
     & X(LCDYX),X(LCDYY),X(LCDYZ),X(LCDZX),X(LCDZY),X(LCDZZ),IFMTDP)
C
   70 CONTINUE
C
C--FOR EACH TRANSPORT STEP..............................................
      TIME2=HT1
      DO N=1,MXSTRN
C
C--ADVANCE ONE TRANSPORT STEP
      CALL BTN4AD(N,TRNOP,TIME1,TIME2,HT2,DELT,KSTP,NSTP,
     & MXPRS,TIMPRS,DT0,MXSTRN,MIXELM,DTRACK,DTRACK2,
     & PERCEL,DTDISP,DTSSM,DTRCT,RFMIN,NPRS,NPS,DTRANS,PRTOUT,
     & NCOL,NROW,NLAY,NCOMP,IX(LCIB),X(LCCNEW),X(LCCOLD),
     & CINACT,UPDLHS,IMPSOL,TTSMULT,TTSMAX,KPER,X(LCDELR),X(LCDELC),
     & X(LCDH),X(LCPR),X(LCSR),X(LCRHOB),X(LCRETA),
     & X(LCPRSITY2),X(LCRETA2),ISOTHM,TMASIO,RMASIO,TMASS)
C
C--FOR EACH COMPONENT......
      DO ICOMP=1,NCOMP
C
C--SOLVE TRANSPORT TERMS WITH EXPLICIT SCHEMES
      IF(IMPSOL.EQ.1 .AND. MIXELM.EQ.0) GOTO 1500
C
C--FORMULATE AND SOLVE
      CALL BTN4SV(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),X(LCCNEW),
     & X(LCCWGT),CINACT,RMASIO)
C
      IF(TRNOP(1) .AND. ICOMP.LE.MCOMP)
     & CALL ADV4SV(IOUT,NCOL,NROW,NLAY,MCOMP,ICOMP,MIXELM,MXPART,
     & NCOUNT,NPINS,NRC,IX(LCCHEK),X(LCXP),X(LCYP),X(LCZP),
     & IX(LCINDX),IX(LCINDY),IX(LCINDZ),X(LCCNPT),IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDZ),X(LCXBC),X(LCYBC),X(LCZBC),X(LCDH),
     & X(LCPR),X(LCQX),X(LCQY),X(LCQZ),X(LCRETA),X(LCCOLD),X(LCCWGT),
     & X(LCCNEW),X(LCCADV),X(LCBUFF),DTRANS,IMPSOL,NADVFD,RMASIO)
C
      IF(IMPSOL.EQ.1) GOTO 1500
C
      IF(TRNOP(2) .AND. ICOMP.LE.MCOMP)
     & CALL DSP4SV(NCOL,NROW,NLAY,MCOMP,ICOMP,IX(LCIB),X(LCDELR),
     & X(LCDELC),X(LCDH),X(LCRETA),X(LCPR),X(LCDXX),X(LCDXY),X(LCDXZ),
     & X(LCDYX),X(LCDYY),X(LCDYZ),X(LCDZX),X(LCDZY),X(LCDZZ),
     & X(LCCNEW),X(LCCWGT),X(LCBUFF),DTRANS,RMASIO)
C
      IF(TRNOP(3) .AND. ICOMP.LE.MCOMP)
     & CALL SSM4SV(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),X(LCPR),
     & X(LCDELR),X(LCDELC),X(LCDH),X(LCRETA),IX(LCIRCH),X(LCRECH),
     & X(LCCRCH),IX(LCIEVT),X(LCEVTR),X(LCCEVT),MXSS,NTSS,NSS,
     & X(LCSS),X(LCSSMC),X(LCQSTO),X(LCCNEW),X(LCCWGT),
     & DTRANS,MIXELM,ISS,RMASIO)
C
      IF(TRNOP(4))
     & CALL RCT4SV(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),X(LCPR),
     & X(LCDELR),X(LCDELC),X(LCDH),X(LCRETA),RFMIN,DTRANS,ISOTHM,
     & IREACT,X(LCRHOB),X(LCSP1),X(LCSP2),X(LCSR),X(LCRC1),
     & X(LCRC2),X(LCPRSITY2),X(LCRETA2),
     & X(LCFRAC),X(LCCNEW),X(LCCWGT),RMASIO)

      GOTO 110
 1500 CONTINUE
C
C--SOLVE TRANSPORT TERMS WITH IMPLICIT SCHEMES
      IF(DTRANS.EQ.0) THEN
        ICNVG=1
        GOTO 110
      ENDIF
C
C--ALWAYS UPDATE MATRIX IF NONLINEAR SORPTION OR MULTICOMPONENT
      IF(TRNOP(4).AND.ISOTHM.GT.1) THEN
        UPDLHS=.TRUE.
      ENDIF
      IF(NCOMP.GT.1) UPDLHS=.TRUE.
C
C--FOR EACH OUTER ITERATION...
      DO ITO=1,MXITER
C
C--UPDATE COEFFICIENTS THAT VARY WITH ITERATIONS
      IF(TRNOP(4).AND.ISOTHM.GT.1)
     & CALL RCT4CF(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),
     & X(LCPR),X(LCCNEW),X(LCRETA),RFMIN,X(LCRHOB),X(LCSP1),
     & X(LCSP2),X(LCRC1),X(LCRC2),X(LCPRSITY2),X(LCRETA2),
     & X(LCFRAC),X(LCSR),ISOTHM,IREACT,DTRANS)
C
C--FORMULATE MATRIX COEFFICIENTS
      CALL BTN4FM(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),X(LCCADV),
     & X(LCCOLD),X(LCRETA),X(LCPR),X(LCDELR),X(LCDELC),X(LCDH),DTRANS,
     & X(LCA),X(LCRHS),NODES,UPDLHS,NCRS,MIXELM)
C
      IF(TRNOP(1).AND.MIXELM.EQ.0 .AND. ICOMP.LE.MCOMP)
     & CALL ADV4FM(NCOL,NROW,NLAY,MCOMP,ICOMP,IX(LCIB),X(LCDELR),
     & X(LCDELC),X(LCDH),X(LCQX),X(LCQY),X(LCQZ),NADVFD,NODES,
     & X(LCA),UPDLHS)
C
      IF(TRNOP(2) .AND. ICOMP.LE.MCOMP)
     & CALL DSP4FM(NCOL,NROW,NLAY,MCOMP,ICOMP,IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDH),X(LCDXX),X(LCDXY),X(LCDXZ),X(LCDYX),
     & X(LCDYY),X(LCDYZ),X(LCDZX),X(LCDZY),X(LCDZZ),
     & X(LCA),NODES,UPDLHS,X(LCCNEW),X(LCRHS),NCRS)
C
      IF(TRNOP(3) .AND. ICOMP.LE.MCOMP)
     & CALL SSM4FM(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDH),IX(LCIRCH),X(LCRECH),X(LCCRCH),
     & IX(LCIEVT),X(LCEVTR),X(LCCEVT),MXSS,NTSS,X(LCSS),X(LCSSMC),
     & X(LCQSTO),X(LCCNEW),ISS,X(LCA),X(LCRHS),NODES,UPDLHS,MIXELM)
C
      IF(TRNOP(4)) CALL RCT4FM(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),
     & X(LCPR),X(LCDELR),X(LCDELC),X(LCDH),ISOTHM,IREACT,
     & X(LCRHOB),X(LCSP1),X(LCSP2),X(LCSR),X(LCRC1),X(LCRC2),
     & X(LCPRSITY2),X(LCRETA2),X(LCFRAC),X(LCA),X(LCRHS),
     & NODES,UPDLHS,DTRANS)
C
      CALL GCG4AP(IOUT,MXITER,ITER1,ITO,ITP,ISOLVE,ACCL,CCLOSE,
     & ICNVG,X(LCCNCG),IX(LCLRCH),NCOL,NROW,NLAY,NODES,N,KSTP,KPER,
     & TIME2,HT2,UPDLHS,IPRGCG,IX(LCIB+(ICOMP-1)*NODES),CINACT,X(LCA),
     & X(LCCNEW+(ICOMP-1)*NODES),X(LCRHS),X(LCQ),X(LCWK),NCRS,ISPD)
C
C--IF CONVERGED, GO TO NEXT OUTER ITERATION
      IF(ICNVG.EQ.1) GOTO 110
C
C--END OF OUTER ITERATION LOOP
      ENDDO
C
  110 CONTINUE
C
C--END OF COMPONENT LOOP
      ENDDO
C
C--CALCULATE MASS BUDGETS AND SAVE RESULTS FOR ALL COMPONENTS
      DO ICOMP=1,NCOMP
C
C--CALCULATE MASS BUDGETS FOR IMPLICIT SCHEMES
C
      IF(IMPSOL.NE.1) GOTO 2000
C
      IF(TRNOP(1).AND.MIXELM.EQ.0 .AND. ICOMP.LE.MCOMP)
     & CALL ADV4BD(IOUT,NCOL,NROW,NLAY,MCOMP,ICOMP,NADVFD,IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDH),X(LCQX),X(LCQY),X(LCQZ),X(LCCNEW),
     & DTRANS,RMASIO)
C
      IF(TRNOP(2) .AND. ICOMP.LE.MCOMP)
     & CALL DSP4BD(NCOL,NROW,NLAY,MCOMP,ICOMP,IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDH),X(LCDXX),X(LCDXY),X(LCDXZ),
     & X(LCDYX),X(LCDYY),X(LCDYZ),X(LCDZX),X(LCDZY),X(LCDZZ),
     & X(LCCNEW),X(LCBUFF),DTRANS,RMASIO)
C
      IF(TRNOP(3) .AND. ICOMP.LE.MCOMP)
     & CALL SSM4BD(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDH),IX(LCIRCH),X(LCRECH),
     & X(LCCRCH),IX(LCIEVT),X(LCEVTR),X(LCCEVT),MXSS,NTSS,
     & X(LCSS),X(LCSSMC),X(LCQSTO),X(LCCNEW),X(LCRETA),
     & DTRANS,ISS,RMASIO)
C
      IF(TRNOP(4)) CALL RCT4BD(NCOL,NROW,NLAY,NCOMP,ICOMP,IX(LCIB),
     & X(LCPR),X(LCDELR),X(LCDELC),X(LCDH),DTRANS,ISOTHM,IREACT,
     & X(LCRHOB),X(LCSP1),X(LCSP2),X(LCSR),X(LCRC1),X(LCRC2),
     & X(LCPRSITY2),X(LCRETA2),X(LCFRAC),X(LCCNEW),X(LCRETA),
     & RFMIN,RMASIO)
C
 2000 CONTINUE
C
C--CALCULATE GLOBAL MASS BUDGETS AND CHECK MASS BALANCE
      CALL BTN4BD(KPER,KSTP,N,NCOL,NROW,NLAY,NCOMP,ICOMP,ISS,IX(LCIB),
     & X(LCDELR),X(LCDELC),X(LCDH),X(LCPR),X(LCRETA),X(LCCNEW),
     & X(LCCOLD),X(LCRHOB),X(LCSR),X(LCPRSITY2),X(LCRETA2),ISOTHM,
     & DTRANS,TMASIN,TMASOT,ERROR,ERROR2,TMASIO,RMASIO,TMASS)
C
C--SAVE OUTPUTS
      CALL BTN4OT(NCOL,NROW,NLAY,KPER,KSTP,N,NCOMP,ICOMP,IOUT,IOBS,
     & IUCN,IUCN2,IMAS,ICBM,MXOBS,NOBS,NPROBS,LOCOBS,
     & IX(LCIB),TIME2,X(LCCNEW),MIXELM,NCOUNT,NPINS,NRC,IX(LCCHEK),
     & ISOTHM,X(LCRETA),X(LCSR),TMASIN,TMASOT,ERROR,ERROR2,TRNOP,
     & TUNIT,MUNIT,PRTOUT,TMASIO,RMASIO,TMASS)
C
      ENDDO
C
      IF(TIME2.GE.HT2) GOTO 900
      IF(IMPSOL.EQ.1.AND.ICNVG.EQ.0) THEN
        WRITE(*,*) 'STOP. GCG SOLVER FAILED TO CONVERGE.'
        STOP
      ENDIF
C
C--END OF TRANSPORT STEP LOOP
      ENDDO
C
      IF(TIME2.LT.HT2) THEN
        WRITE(IOUT,810) MXSTRN
  810   FORMAT(/1X,'NUMBER OF TRANSPORT STEPS EXCEEDS',
     &   ' SPECIFIED MAXIMUM (MXSTRN) =',I10)
        STOP
      ENDIF
  900 CONTINUE
C
C--END OF FLOW TIME STEP LOOP
      ENDDO
C
C--END OF STRESS PERIOD LOOP
      ENDDO
C
C--DEALLOCATE MEMORY
      DEALLOCATE (X,IX)
C
C--PROGRAM COMPLETED
      WRITE(IOUT,1200)
      WRITE(IOUT,1225)
      WRITE(IOUT,1200)
 1200 FORMAT(1X,' ----- ')
 1225 FORMAT(1X,'| M T |'
     &      /1X,'| 3 D | END OF MODEL OUTPUT')
C
C--Get CPU time at the end of simulation
C--and print out total elapsed time in seconds
      Call CPU_TIME(end_time)
      total_time = end_time - start_time
      Write(*,2010) int(total_time/60.),mod(total_time,60.)
 2010 FORMAT(/1X,'Program completed.   ',
     & 'Total CPU time:',i5.3,' minutes ',f6.3,' seconds')
C
      STOP
      END
