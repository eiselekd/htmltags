if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].tree)
    top[document.htmltagid].tree = {};



// Node object
top[document.htmltagid].treeNode = function(tree, id, pid, name, url, title, target, icon, iconOpen, open) {
    this.tree = tree;
    this.id = id;
    this.pid = pid;
    this.name = name;
    this.url = url;
    this.title = title;
    this.target = target;
    this.icon = icon;
    this.iconOpen = iconOpen;
    this._io = open || false;
    this._is = false;
    this._ls = false;
    this._hc = false;
    this._ai = 0;
    this._p;
    this._hidden = false;
};

// Tree object
top[document.htmltagid].tree = function (objName) {
    this.config = {
        target			: null,
        folderLinks		: true,
        useSelection		: true,
        useCookies		: true,
        useLines		: true,
        useIcons		: true,
        useStatusText		: false,
        closeSameLevel		: false,
        inOrder			: false,
        life		        : false 
    }
    this.icon = {
        root			: 'img/base.gif',
        folder			: 'img/folder.gif',
        folderOpen		: 'img/folderopen.gif',
        node			: 'img/page.gif',
        empty			: 'img/empty.gif',
        line			: 'img/line.gif',
        join			: 'img/join.gif',
        joinBottom		: 'img/joinbottom.gif',
        plus			: 'img/plus.gif',
        plusBottom		: 'img/plusbottom.gif',
        minus			: 'img/minus.gif',
        minusBottom		: 'img/minusbottom.gif',
        nlPlus			: 'img/nolines_plus.gif',
        nlMinus			: 'img/nolines_minus.gif'
    };
    this.obj = objName;
    this.aNodes = [];
    this.aIndent = [];
    this.lookup = new Array();
    this.root = new top[document.htmltagid].treeNode(this,-1);
    this.selectedNode = null;
    this.selectedFound = false;
    this.completed = false;
};

// Adds a new node to the node array
top[document.htmltagid].tree.prototype.addtree = function(tree, id, pid, name, url, title, target, icon, iconOpen, open) {
    var node = new top[document.htmltagid].treeNode(this, id, pid, name, url, title, target, icon, iconOpen, open);
    node._subtree = tree;
    this.addnode(node,id, pid, name, url, title, target, icon, iconOpen, open);
    return node;
};

// Adds a new node to the node array
top[document.htmltagid].tree.prototype.add = function(id, pid, name, url, title, target, icon, iconOpen, open) {
    var node = new top[document.htmltagid].treeNode(this, id, pid, name, url, title, target, icon, iconOpen, open);
    this.addnode(node,id, pid, name, url, title, target, icon, iconOpen, open);
    return node;
};

// Adds a new node to the node array
top[document.htmltagid].tree.prototype.addnode = function(node,id, pid, name, url, title, target, icon, iconOpen, open) {
    var aid = this.aNodes.length;
    this.lookup[aid] = node;
    this.aNodes[aid] = node;
    if (this.config.life) {
        this.aIndent = [];
        var pnode = node;
        while (typeof(pnode) != "undefined" &&  pnode.pid != 0 &&
               typeof(pnode.pid) != "undefined") {
            pnode = this.aNodes[pnode.pid];
            this.aIndent.push(1);
        }
        var str = this.node.call(this, node, id, 1);
        var pidn = 'd' + this.obj + pid;
        var pidni = 'di' + this.obj + pid;
        var preppidn = pidn.replace(/\./g,'\\.').replace(/\'/g,'\\\'').replace(/\[/g,'\\[').replace(/\]/g,'\\]');
        var preppidni = pidni.replace(/\./g,'\\.').replace(/\'/g,'\\\'').replace(/\[/g,'\\[').replace(/\]/g,'\\]');
        var g = $('#'+preppidn);
        if (g.length == 0) {
            cstr = '<div id="d' + this.obj + pid + '" class="clip" style="display:' + (this.root.id == node.pid || node.pid == 0 || node._io ? 'block' : 'none') + ';">';
            cstr += str;
            cstr += '</div>';
            $('#'+preppidni).after(cstr);
        } else { 
            $('#'+preppidn).append(str);
        }
        
        for (var n=0; n<this.aNodes.length; n++) 
            this.setCS.call(this,this.aNodes[n]);
        this.aIndent = new Array();
        this.reImage.call(this,this.root);
    }
};

// Open/close all nodes
top[document.htmltagid].tree.prototype.openAll = function() {
    this.oAll(true);
};
top[document.htmltagid].tree.prototype.closeAll = function() {
    this.oAll(false);
};

// Outputs the tree to the page
top[document.htmltagid].tree.prototype._toString = function(prefix,noroot) {
    var str = '<div class="dtree">\n';
    this._prefix = "";
    this.root._hidden = noroot;
    if (typeof(prefix) != "undefined")
        this._prefix = prefix;
    if (document.getElementById) {
        if (this.config.useCookies) this.selectedNode = this.getSelected();
        str += this.addNode(this.root);
    } else str += 'Browser not supported.';
    str += '</div>';
    if (!this.selectedFound) this.selectedNode = null;
    this.completed = true;
    this.config.life = true;
    this.root._hidden = false;
    return str;
};

top[document.htmltagid].tree.prototype.getNode = function(id) {
    var n=0;
    for (n; n<this.aNodes.length; n++) {
        if (this.aNodes[n].id == id) {
            return this.aNodes[n];
        }
    }
    return undefined;
}

// Creates the tree structure
top[document.htmltagid].tree.prototype.addNode = function(pNode) {
    var str = '';
    var n=0;
    if (this.config.inOrder) n = pNode._ai;
    for (n; n<this.aNodes.length; n++) {
        if (this.aNodes[n].pid == pNode.id) {
            var cn = this.aNodes[n];
            cn._p = pNode;
            cn._ai = n;
            this.setCS(cn);
            if (!cn.target && this.config.target) cn.target = this.config.target;
            if (cn._hc && !cn._io && this.config.useCookies) cn._io = this.isOpen(cn.id);
            if (!this.config.folderLinks && cn._hc) cn.url = null;
            if (this.config.useSelection && cn.id == this.selectedNode && !this.selectedFound) {
                cn._is = true;
                this.selectedNode = n;
                this.selectedFound = true;
            }
            str += this.node(cn, cn.id, -1);
            if (cn._ls) break;
        }
    }
    return str;
};

top[document.htmltagid].tree.prototype.issubtree = function(node) {
    return (typeof(node._subtree) != "undefined");
}

// Creates the node icon, url and text
top[document.htmltagid].tree.prototype.node = function(node, nodeId, dyn) {
    if (this.issubtree(node)) {
        this.indent(node, nodeId, false);
        node._subtree._prefix = node.subtreestr;
        return node._subtree._toString(node.subtreestr,true);
    }
    var str = '<div class="dTreeNode" id="di'+this.obj + nodeId+'">' + this._prefix + this.indent(node, nodeId, false);
    if (this.config.useIcons) {
        if (!node.icon) node.icon = (0 && this.root.id == node.pid) ? this.icon.root : ((node._hc) ? this.icon.folder : this.icon.node);
        if (!node.iconOpen) node.iconOpen = (node._hc) ? this.icon.folderOpen : this.icon.node;
        if (0 && this.root.id == node.pid) {
            node.icon = this.icon.root;
            node.iconOpen = this.icon.root;
        }
        str += '<img id="i' + this.obj + nodeId + '" src="' + ((node._io) ? node.iconOpen : node.icon) + '" alt="" />';
    }
    if (node.url) {
        str += '<a id="s' + this.obj + nodeId + '" class="' + ((this.config.useSelection) ? ((node._is ? 'nodeSel' : 'node')) : 'node') + '" href="' + node.url + '"';
        if (node.title) str += ' title="' + node.title + '"';
        if (node.target) str += ' target="' + node.target + '"';
        if (this.config.useStatusText) str += ' onmouseover="window.status=\'' + node.name + '\';return true;" onmouseout="window.status=\'\';return true;" ';
        if (this.config.useSelection && ((node._hc && this.config.folderLinks) || !node._hc))
            str += ' onclick="javascript: ' + this.obj + '.s(' + nodeId + ');"';
        str += '>';
    }
    else if ((!this.config.folderLinks || !node.url) && node._hc && node.pid != this.root.id)
        str += '<a href="javascript: ' + this.obj + '.o(' + nodeId + ');" class="node">';
    str += node.name;
    if (node.url || ((!this.config.folderLinks || !node.url) && node._hc)) str += '</a>';
    str += '</div>';
    if (node._hidden)
        str = "";
    if (node._hc && dyn == -1) {
        if (!node._hidden)
            str += '<div id="d' + this.obj + nodeId + '" class="clip" style="display:' + ((this.root.id == node.pid || node._io) ? 'block' : 'none') + ';">';
        str += this.addNode(node);
        if (!node._hidden)
            str += '</div>';
    }
    if (dyn == -1)
        this.aIndent.pop();
    return str;
};

// Creates the node icon, url and text
top[document.htmltagid].tree.prototype.reImage = function(pNode) {
    var str = ''; var p = pNode;
    var n=0;
    /*
    alert("size " + this.aNodes.length);
    for (n = 0; n<this.aNodes.length; n++) {
        alert(n+":" + this.aNodes[n].pid + " searching for " + p.id);
        }*/
    for (n = 0; n<this.aNodes.length; n++) {
        if (this.aNodes[n].pid == p.id) {
            var cn = this.aNodes[n];
            cn._p = p;
            cn._ai = n;
            this.setCS(cn);
            
            this.indent.call(this, cn, n, true);
            this.reImage.call(this,cn);
            this.aIndent.pop();

            if (cn._ls) break;
        }
    }
    return str;
};

// Adds the empty and line icons
top[document.htmltagid].tree.prototype.indent = function(node, nodeId, dyn) {
    var str = '';
    var subtreestr = '';
    if (this.root.id != node.pid) {
        for (var n=0; n<this.aIndent.length; n++) {
            if (dyn) {
            }
            var id = 'in' + this.obj + nodeId + '.' + n ;
            var src = ( (this.aIndent[n] == 1 && this.config.useLines) ? this.icon.line : this.icon.empty );
            str += '<img id="' + id + '" src="' + src + '" alt="" />';
            subtreestr += '<img class="' + id.replace(/\./g,'_') + '" src="' + src + '" alt="" />';
            if (dyn) {
                $('#'+id.replace(/\./g,'\\.').replace(/\'/g,'\\\'').replace(/\[/g,'\\[').replace(/\]/g,'\\]')).attr('src',src);
                $('#'+id.replace(/\./g,'\\.').replace(/\'/g,'\\\'').replace(/\[/g,'\\[').replace(/\]/g,'\\]')).attr('alt','modiefied');
                $('.'+id.replace(/\./g,'_')).attr('src',src);
                $('.'+id.replace(/\./g,'_')).attr('alt','modiefied');
            }
        }
        
        (node._ls) ? this.aIndent.push(0) : this.aIndent.push(1);
        if (dyn) {
            
        }
        var aid = 'a' + this.obj + nodeId;
        var id = 'j' + this.obj + nodeId;
        var src = "";
        var href = 'javascript:(function(){})();';
        if (node._hc) {
            href = 'javascript: ' + this.obj + '.o(' + nodeId + ');';
            str += '<a id="'+aid+'" href="'+href+'"><img id="' + id + '" src="';
            if (!this.config.useLines) src = (node._io) ? this.icon.nlMinus : this.icon.nlPlus;
            else src = ( (node._io) ? ((node._ls && this.config.useLines) ? this.icon.minusBottom : this.icon.minus) : ((node._ls && this.config.useLines) ? this.icon.plusBottom : this.icon.plus ) );
            str += src + '" alt="" /></a>';
        } else {
            src = ( (this.config.useLines) ? ((node._ls) ? this.icon.joinBottom : this.icon.join ) : this.icon.empty);
            str += '<a id="'+aid+'" href="'+href+'"><img id="'+ id +'" src="' + src + '" alt="" />';
        }
        if (dyn) {
            $('#'+id.replace(/\./g,'\\.').replace(/\'/g,'\\\'').replace(/\[/g,'\\[').replace(/\]/g,'\\]')).attr('src',src);
            $('#'+aid.replace(/\./g,'\\.').replace(/\'/g,'\\\'').replace(/\[/g,'\\[').replace(/\]/g,'\\]')).attr('href',href);
        }
        
    }
    node.subtreestr = subtreestr;
    return str;
};

// Checks if a node has any children and if it is the last sibling
top[document.htmltagid].tree.prototype.setCS = function(node) {
    var lastId;
    node._hc = true;
    node._ls = false;
    for (var n=0; n<this.aNodes.length; n++) {
        if (this.aNodes[n].pid == node.id) node._hc = true;
        if (this.aNodes[n].pid == node.pid) lastId = this.aNodes[n].id;
    }
    if (lastId==node.id) node._ls = true;
};

// Returns the selected node
top[document.htmltagid].tree.prototype.getSelected = function() {
    var sn = this.getCookie('cs' + this.obj);
    return (sn) ? sn : null;
};

// Highlights the selected node
top[document.htmltagid].tree.prototype.s = function(id) {
    if (!this.config.useSelection) return;
    var cn = this.aNodes[id];
    if (!cn || (cn._hc && !this.config.folderLinks)) return;
    if (this.selectedNode != id) {
        if (this.selectedNode || this.selectedNode==0) {
            eOld = document.getElementById("s" + this.obj + this.selectedNode);
            if (eOld)
                eOld.className = "node";
        }
        eNew = document.getElementById("s" + this.obj + id);
        eNew.className = "nodeSel";
        this.selectedNode = id;
        if (this.config.useCookies) this.setCookie('cs' + this.obj, cn.id);
    }
};

top[document.htmltagid].tree.prototype.oc = function(id,openclose) {
    var cn = this.getNode(id);
    if (typeof(cn) != "undefined") {
	if (openclose) {
	    if (cn._io)
		return;
	} else {
	    if (!cn._io)
		return;
	}
    }
    this.o(id);
}
    
// Toggle Open or close
top[document.htmltagid].tree.prototype.o = function(id) {
    var cn = this.getNode(id);
    if (typeof(cn) != "undefined") {
	this.nodeStatus(!cn._io, id, cn._ls);
	cn._io = !cn._io;
	if (this.config.closeSameLevel) this.closeLevel(cn);
	if (this.config.useCookies) this.updateCookie();
	if (typeof(cn._custom_open_url) != "undefined") {
	    eval(cn._custom_open_url+","+(cn._io ? 1 : 0)+")");
	}
    }
};

// Open or close all nodes
top[document.htmltagid].tree.prototype.oAll = function(status) {
    for (var n=0; n<this.aNodes.length; n++) {
        if (this.aNodes[n]._hc && this.aNodes[n].pid != this.root.id) {
            this.nodeStatus(status, n, this.aNodes[n]._ls)
            this.aNodes[n]._io = status;
        }
    }
    if (this.config.useCookies) this.updateCookie();
};

// Opens the tree to a specific node
top[document.htmltagid].tree.prototype.openTo = function(nId, bSelect, bFirst) {
    if (!bFirst) {
        for (var n=0; n<this.aNodes.length; n++) {
            if (this.aNodes[n].id == nId) {
                nId=n;
                break;
            }
        }
    }
    var cn=this.aNodes[nId];
    if (cn.pid==this.root.id || !cn._p) return;
    cn._io = true;
    cn._is = bSelect;
    if (this.completed && cn._hc) this.nodeStatus(true, cn._ai, cn._ls);
    if (this.completed && bSelect) this.s(cn._ai);
    else if (bSelect) this._sn=cn._ai;
    this.openTo(cn._p._ai, false, true);
};

// Closes all nodes on the same level as certain node
top[document.htmltagid].tree.prototype.closeLevel = function(node) {
    for (var n=0; n<this.aNodes.length; n++) {
        if (this.aNodes[n].pid == node.pid && this.aNodes[n].id != node.id && this.aNodes[n]._hc) {
            this.nodeStatus(false, n, this.aNodes[n]._ls);
            this.aNodes[n]._io = false;
            this.closeAllChildren(this.aNodes[n]);
        }
    }
}
    
// Closes all children of a node
top[document.htmltagid].tree.prototype.closeAllChildren = function(node) {
    for (var n=0; n<this.aNodes.length; n++) {
        if (this.aNodes[n].pid == node.id && this.aNodes[n]._hc) {
            if (this.aNodes[n]._io) this.nodeStatus(false, n, this.aNodes[n]._ls);
            this.aNodes[n]._io = false;
            this.closeAllChildren(this.aNodes[n]);		
        }
    }
}

// Change the status of a node(open or closed)
top[document.htmltagid].tree.prototype.nodeStatus = function(status, id, bottom) {
    eDiv	= document.getElementById('d' + this.obj + id);
    eJoin	= document.getElementById('j' + this.obj + id);
    if (this.config.useIcons && this.aNodes[id]) {
        eIcon	= document.getElementById('i' + this.obj + id);
        eIcon.src = (status) ? this.aNodes[id].iconOpen : this.aNodes[id].icon;
    }
    eJoin.src = (this.config.useLines)?
    ((status)?((bottom)?this.icon.minusBottom:this.icon.minus):((bottom)?this.icon.plusBottom:this.icon.plus)):
    ((status)?this.icon.nlMinus:this.icon.nlPlus);
    eDiv.style.display = (status) ? 'block': 'none';
};


// [Cookie] Clears a cookie
top[document.htmltagid].tree.prototype.clearCookie = function() {
    var now = new Date();
    var yesterday = new Date(now.getTime() - 1000 * 60 * 60 * 24);
    this.setCookie('co'+this.obj, 'cookieValue', yesterday);
    this.setCookie('cs'+this.obj, 'cookieValue', yesterday);
};

// [Cookie] Sets value in a cookie
top[document.htmltagid].tree.prototype.setCookie = function(cookieName, cookieValue, expires, path, domain, secure) {
    document.cookie =
    escape(cookieName) + '=' + escape(cookieValue)
    + (expires ? '; expires=' + expires.toGMTString() : '')
    + (path ? '; path=' + path : '')
    + (domain ? '; domain=' + domain : '')
    + (secure ? '; secure' : '');
};

// [Cookie] Gets a value from a cookie
top[document.htmltagid].tree.prototype.getCookie = function(cookieName) {
    var cookieValue = '';
    var posName = document.cookie.indexOf(escape(cookieName) + '=');
    if (posName != -1) {
        var posValue = posName + (escape(cookieName) + '=').length;
        var endPos = document.cookie.indexOf(';', posValue);
        if (endPos != -1) cookieValue = unescape(document.cookie.substring(posValue, endPos));
        else cookieValue = unescape(document.cookie.substring(posValue));
    }
    return (cookieValue);
};

// [Cookie] Returns ids of open nodes as a string
top[document.htmltagid].tree.prototype.updateCookie = function() {
    var str = '';
    for (var n=0; n<this.aNodes.length; n++) {
        if (this.aNodes[n]._io && this.aNodes[n].pid != this.root.id) {
            if (str) str += '.';
            str += this.aNodes[n].id;
        }
    }
    this.setCookie('co' + this.obj, str);
};

// [Cookie] Checks if a node id is in a cookie
top[document.htmltagid].tree.prototype.isOpen = function(id) {
    var aOpen = this.getCookie('co' + this.obj).split('.');
    for (var n=0; n<aOpen.length; n++)
        if (aOpen[n] == id) return true;
    return false;
};

// Remove node
top[document.htmltagid].tree.prototype.removeNode = function(id) {
    var e; var ei;
    if (e = document.getElementById("di" + this.obj + id))
        e.parentNode.removeChild(e);
    if (ef = document.getElementById("d" + this.obj + id))
        ef.parentNode.removeChild(ef);
};

// If Push and pop is not implemented by the browser
if (!Array.prototype.push) {
    Array.prototype.push = function array_push() {
        for(var i=0;i<arguments.length;i++)
            this[this.length]=arguments[i];
        return this.length;
    }
};
if (!Array.prototype.pop) {
    Array.prototype.pop = function array_pop() {
        lastElement = this[this.length-1];
        this.length = Math.max(this.length-1,0);
        return lastElement;
    }
};