#!/bin/sh
for zstep in - +
do
    for type in byte ubyte short ushort long ulong float double
    do

       case "$type" in
            "ubyte")  opts='-byte -unsigned'
               ;;
            "byte")   opts='-byte -signed'
               ;;
            "ushort") opts='-short -unsigned'
               ;;
            "ushort") opts='-short -signed'
               ;;
            "ulong")  opts='-long -unsigned'
               ;;
            "long")   opts='-long -signed'
               ;;
            "float")  opts='-float'
               ;;
            "double") opts='-double'
               ;;
       esac

       for view in cor trans sag
       do
          mincreshape -dimsize "zspace"=-1 -dimsize "yspace"=-1 -dimsize "xspace"=-1 "$zstep"zdirection -clob -${view} $1 $opts "$2"_${zstep}_${type}_${view}.mnc
       done

       mincreshape -dimsize "zspace"=-1 -dimsize "yspace"=-1 -dimsize "xspace"=-1 ${zstep}zdirection -clob -dimorder xspace,yspace,zspace $opts $1 "$2"_${zstep}_${type}_xyz.mnc
       mincreshape -dimsize "zspace"=-1 -dimsize "yspace"=-1 -dimsize "xspace"=-1 ${zstep}zdirection -clob -dimorder yspace,zspace,xspace $opts $1 "$2"_${zstep}_${type}_yzx.mnc
       mincreshape -dimsize "zspace"=-1 -dimsize "yspace"=-1 -dimsize "xspace"=-1 ${zstep}zdirection -clob -dimorder zspace,xspace,yspace $opts $1 "$2"_${zstep}_${type}_zxy.mnc

       rm -f mnc_${type}.mnc
    done
done
