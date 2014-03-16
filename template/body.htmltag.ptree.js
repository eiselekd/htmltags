if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].ptree)
    top[document.htmltagid].ptree = {};
if (!top[document.htmltagid].pindex)
    top[document.htmltagid].pindex = {};

top[document.htmltagid].ptree.nextID = 1;

top[document.htmltagid]._ptree = function(objname,pathdef,loc) {
    this._pathdef = pathdef;
    this._loc = loc;
    this.createIdx(objname);
}
    
top[document.htmltagid]._ptree.prototype.createIdx = function (objname) {
        
    var p = this._pathdef;
    var id = top[document.htmltagid].ptree.nextID++;
    this.tree = new top[document.htmltagid].tree(objname);
    this.tree.add(0,-1,'Source','javascript: void(0);');
    
    if (p && p.fids && p.fids.length > 0) {
        for (var i=0; i<p.fids.length; i++) {
            var fid = p.fids[i];
            var path = p.paths[fid];
            var pid = path.p;
            var link = path.l;
            var linkother = path.lo;
            var name = path.n;
            var _link = link.replace(/@/g,this._loc);
            
            if (typeof(pid) == "undefined") 
                pid = 0;
            var node = this.tree.add(fid, pid,name,_link);
	    node._custom_open_url = linkother;
        }
    }
    var n = this.tree.getNode(0);
    if (n)
        n._hidden = true;
}
    
top[document.htmltagid]._pindex = function (objname)  {
    this._n = objname;
    this._paths = new Array();
    this.tree = new top[document.htmltagid].tree(objname);
    this.tree.add(0,-1,'Source','javascript: void(0);');
    
}

top[document.htmltagid]._pindex.prototype.addPath = function (path,obj)  {
    var o = this;
    var a = path.split(/\//);
    var p = ""; var pid = 0;
    for (e in a) {
        if (p != "") 
            p += "/";
        p += a[e];
        if (typeof(this._paths[p]) == "undefined") {
            var i = this.tree.aNodes.length;
            this.tree.add.call(this.tree,i,pid,a[e],'javascript: '+this._n+'.removeNode2('+i+');');
            this._paths[p] = i;
        }
        pid = this._paths[p];
    }
    var i = this.tree.aNodes.length;
    this.tree.addtree.call(this.tree,obj,i,pid,"tree",'javascript: '+this._n+'.removeNode2('+i+');');
    
}

