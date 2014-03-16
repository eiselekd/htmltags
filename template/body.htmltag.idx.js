if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].idx)
    top[document.htmltagid].idx = {};

top[document.htmltagid].idx.p = undefined; // init by top.main
top[document.htmltagid].idx.done = new Array();
top[document.htmltagid].idx.nextID = 1;

top[document.htmltagid].idx.setidx = function (pathdef,filename) {
    var id = top[document.htmltagid].idx.nextID;
     top[document.htmltagid].idx.done[   id   ] = new top[document.htmltagid]._ptree(
    "top[document.htmltagid].idx.done['"+id+"'].tree",pathdef,pathdef.basedir);
    top["htmltagidx"].indexes.addPath.call(top["htmltagidx"].indexes,pathdef.basedir,
     top[document.htmltagid].idx.done[   id   ].tree);
    
}

top[document.htmltagid].idx.search = function (pathdef) {
    for (e in top[document.htmltagid].idx.done) {
	if (top[document.htmltagid].idx.done[e]._pathdef.fileid == pathdef.fileid &&
	    top[document.htmltagid].idx.done[e]._pathdef.filename == pathdef.filename) {
	    return e;
	}
    }
    return -1;
}

top[document.htmltagid].idx.openclosepath = function (pathdef,fid,openclose) {
    var idx = top[document.htmltagid].idx.search(pathdef);
    if (idx != -1) {
	top[document.htmltagid].idx.done[idx].tree.oc(fid,openclose);
    }
}
    
top[document.htmltagid].idx.opencloseother = function (id,openclose) {
    top[document.htmltagid_other].idx.openclosepath(top[document.htmltagid].path.pathdef,id,openclose);
}

    