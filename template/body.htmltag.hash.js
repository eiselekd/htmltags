if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].hash)
    top[document.htmltagid].hash = {};

top[document.htmltagid].hash.hashListener = {
    ie:		/MSIE/.test(navigator.userAgent),
    ieSupportBack:	true,
    hash:	document.location.hash,
    check:	function () {
	var h = document.location.hash;
	if (h != this.hash) {
	    this.hash = h;
	    this.onHashChanged();
	}
	
    },
    init:	function () {
	
	// for IE we need the iframe state trick
	if (this.ie && this.ieSupportBack) {
	    var frame = document.createElement("iframe");
	    frame.id = "state-frame";
	    frame.style.display = "none";
	    if (document.body) {
		document.body.appendChild(frame);
		this.writeFrame("");
	    } else {
		alert("No document body present\n");
	    }
	}
	
	var self = this;
	
	// IE
	if ("onpropertychange" in document && "attachEvent" in document) {
	    document.attachEvent("onpropertychange", function () {
		    if (event.propertyName == "location") {
			self.check();
		    }
		});
	}
	// poll for changes of the hash
	window.setInterval(function () { self.check() }, 500);
    },
    setHash: function (s) {
	// Mozilla always adds an entry to the history
	if (this.ie && this.ieSupportBack) {
	    this.writeFrame(s);
	}
	document.location.hash = s;
    },
    getHash: function () {
	return document.location.hash;
    },
    writeFrame:	function (s) {
	var f = document.getElementById("state-frame");
	if (f) {
	    var d = f.contentDocument || f.contentWindow.document;
	    d.open();
	    d.write("<script>window._hash = '" + s + "'; window.onload = parent.top[document.htmltagid].hash.hashListener.syncHash;<\/script>");
	    d.close();
	}
    },
    syncHash:	function () {
	var s = this._hash;
	if (s != document.location.hash) {
	    document.location.hash = s;
	}
    },
    onHashChanged:	function () {}
};

top[document.htmltagid].hash.hashListener.onHashChanged = function () {
    if (top[document.htmltagid].hash.hashListener.hash.length > 0 &&
	top[document.htmltagid].hash.hashListener.hash.substr(0,1) == '#') {
	var h = top[document.htmltagid].hash.hashListener.hash.substr(1);
	var e;
	//alert(h);
	if (e = document.getElementById(h)) {
	    if (e.style.pixelTop) {
		window.scrollTo(1,e.style.pixelTop);
	    } else if (e.offsetTop) {
		window.scrollTo(1,e.offsetTop);
                   } else {
		window.scrollTo(1,e.style.top);
		/*e.style.top=y_mouse;
		  e.style.left=x_mouse;*/
	    }
            
	} if (e = document.getElementsByName(h)) {
	    if (e.length > 0) {
		var e = e[0];
		if (e.style.pixelTop && e.style.pixelLeft) {
		    window.scrollTo(1,e.style.pixelTop);
		} else if (e.offsetTop) {
		    window.scrollTo(1,e.offsetTop);
		} else {
		    window.scrollTo(0, e.style.top);
		}
	    }
	}
    }
};


