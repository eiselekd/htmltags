if (!top.htmltag)
    top.htmltag = { };
if (!top.htmltag.span)
    top.htmltag.span = { };

top.htmltag.span.replaceSpan = function (elem,str) {
        var span = top.htmltag.find_ancestor(elem,"span");
        if (span == null) {
		return;
	}
	span.innerHTML = unescape(str);
};

top.htmltag.span.showstruct = function ( thisid, id) {
    top.htmltag.win.CreateDropdownWindow( document.getElementById('A'+thisid) ,"struct", id, true /*false*/);
};
