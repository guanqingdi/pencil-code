;
; $Id$
;
;  Pencil-Code unified reading routine
;
;  Author: Philippe Bourdin
;  $Date: 2019-04-07 11:56:32 $
;  $Revision: 1.0 $
;
;  07-Apr-2019/PABourdin: coded
;
function pc_read, quantity, filename=filename, datadir=datadir, trimall=trim, processor=processor, dim=dim, start=start, count=count

	COMPILE_OPT IDL2,HIDDEN

	common pc_read_common, file

	particles = (strpos (strlowcase (quantity) ,'part/') ge 0)

	if (keyword_set (filename)) then begin
		if (not keyword_set (datadir)) then datadir = pc_get_datadir (datadir)
		file = datadir+'/allprocs/'+filename
	end

	if (size (processor, /type) ne 0) then begin
		if (keyword_set (particles)) then begin
			distribution = hdf5_read ('proc/distribution', filename=file)
			start = 0
			if (processor ge 1) then start = total (distribution[0:processor-1])
			count = distribution[processor]
			return, hdf5_read (quantity, start=start, count=count)
		end else begin
			if (size (dim, /type) eq 0) then pc_read_dim, obj=dim, datadir=datadir, proc=proc
			ipx = processor mod dim.nprocx
			ipy = (processor / dim.nprocx) mod dim.nprocy
			ipz = processor / (dim.nprocx * dim.nprocy)
                        nx = dim.nxgrid / dim.nprocx
                        ny = dim.nygrid / dim.nprocy
                        nz = dim.nzgrid / dim.nprocz
                        ghost = [ dim.nghostx, dim.nghosty, dim.nghostz ]
			start = [ ipx*nx, ipy*ny, ipz*nz ]
			count = [ nx, ny, nz ] + ghost * 2
		end
	end

	if (not keyword_set (particles)) then begin
		if (strpos (strlowcase (quantity) ,'/') lt 0) then quantity = 'data/'+quantity
		if (keyword_set (trim)) then begin
			default, start, [ 0, 0, 0 ]
			default, count, [ dim.mxgrid, dim.mygrid, dim.mzgrid ]
			if (size (dim, /type) eq 0) then pc_read_dim, obj=dim, datadir=datadir
                        ghost = [ dim.nghostx, dim.nghosty, dim.nghostz ]
			degenerated = where (count eq 1, num_degenerated)
			if (num_degenerated gt 0) then ghost[degenerated] = 0
			return, hdf5_read (quantity, filename=file, start=start+ghost, count=count-ghost*2)
		end
	end

	return, hdf5_read (quantity, filename=file, start=start, count=count)
end

