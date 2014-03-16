<?php	
if (!isset($CFWSAJAX_INCLUDED)) {

	/*  
	 * GLOBALS AND DEFAULTS
	 *
	 */ 
	$GLOBALS['cfwsajax_version'] = '0.12';	
	$GLOBALS['cfwsajax_debug_mode'] = 0;
	$GLOBALS['cfwsajax_export_list'] = array();
	$GLOBALS['cfwsajax_request_type'] = 'GET';
	$GLOBALS['cfwsajax_remote_uri'] = '';
	$GLOBALS['cfwsajax_failure_redirect'] = '';
	
	/*
	 * CODE
	 *
	 */ 
	 
	//
	// Initialize the Cfwsajax library.
	//
	function cfwsajax_init() {
	}
	
	//
	// Helper function to return the script's own URI. 
	// 
	function cfwsajax_get_my_uri() {
		return $_SERVER["REQUEST_URI"];
	}
	$cfwsajax_remote_uri = cfwsajax_get_my_uri();
	
	//
	// Helper function to return an eval()-usable representation
	// of an object in JavaScript.
	// 
	function cfwsajax_get_js_repr($value) {
		$type = gettype($value);
		
		if ($type == "boolean") {
			return ($value) ? "Boolean(true)" : "Boolean(false)";
		} 
		elseif ($type == "integer") {
			return "parseInt($value)";
		} 
		elseif ($type == "double") {
			return "parseFloat($value)";
		} 
		elseif ($type == "array" || $type == "object" ) {
			//
			// XXX Arrays with non-numeric indices are not
			// permitted according to ECMAScript, yet everyone
			// uses them.. We'll use an object.
			// 
			$s = "{ ";
			if ($type == "object") {
				$value = get_object_vars($value);
			} 
			foreach ($value as $k=>$v) {
				$esc_key = cfwsajax_esc($k);
				if (is_numeric($k)) 
					$s .= "$k: " . cfwsajax_get_js_repr($v) . ", ";
				else
					$s .= "\"$esc_key\": " . cfwsajax_get_js_repr($v) . ", ";
			}
			if (count($value))
				$s = substr($s, 0, -2);
			return $s . " }";
		} 
		else {
			$esc_val = cfwsajax_esc($value);
			$s = "'$esc_val'";
			return $s;
		}
	}

	function cfwsajax_handle_client_request() {
		global $cfwsajax_export_list;
		
		$mode = "";
		
		if (! empty($_GET["rs"])) 
			$mode = "get";
		
		if (!empty($_POST["rs"]))
			$mode = "post";
			
		if (empty($mode)) 
			return;

		$target = "";
		
		if ($mode == "get") {
			// Bust cache in the head
			header ("Expires: Mon, 26 Jul 1997 05:00:00 GMT");    // Date in the past
			header ("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
			// always modified
			header ("Cache-Control: no-cache, must-revalidate");  // HTTP/1.1
			header ("Pragma: no-cache");                          // HTTP/1.0
			$func_name = $_GET["rs"];
			if (! empty($_GET["rsargs"])) 
				$args = $_GET["rsargs"];
			else
				$args = array();
		}
		else {
			$func_name = $_POST["rs"];
			if (! empty($_POST["rsargs"])) 
				$args = $_POST["rsargs"];
			else
				$args = array();
		}
		
		if (! in_array($func_name, $cfwsajax_export_list))
			echo "-:$func_name not callable";
		else {
			echo "+:";
			$result = call_user_func_array($func_name, $args);
			echo "var res = " . trim(cfwsajax_get_js_repr($result)) . "; res;";
		}
		exit;
	}
	
	function cfwsajax_get_common_js() {
		global $cfwsajax_debug_mode;
		global $cfwsajax_request_type;
		global $cfwsajax_remote_uri;
		global $cfwsajax_failure_redirect;
		
		$t = strtoupper($cfwsajax_request_type);
		if ($t != "" && $t != "GET" && $t != "POST") 
			return "// Invalid type: $t.. \n\n";
		
		ob_start();
		?>
		
		// remote scripting library
		// (c) copyright 2005 modernmethod, inc
		var cfwsajax_debug_mode = <?php echo $cfwsajax_debug_mode ? "true" : "false"; ?>;
		var cfwsajax_request_type = "<?php echo $t; ?>";
		var cfwsajax_target_id = "";
		var cfwsajax_failure_redirect = "<?php echo $cfwsajax_failure_redirect; ?>";
		
		function cfwsajax_debug(text) {
			if (cfwsajax_debug_mode)
				alert(text);
		}
		
 		function cfwsajax_init_object() {
 			cfwsajax_debug("cfwsajax_init_object() called..")
 			
 			var A;
 			
 			var msxmlhttp = new Array(
				'Msxml2.XMLHTTP.5.0',
				'Msxml2.XMLHTTP.4.0',
				'Msxml2.XMLHTTP.3.0',
				'Msxml2.XMLHTTP',
				'Microsoft.XMLHTTP');
			for (var i = 0; i < msxmlhttp.length; i++) {
				try {
					A = new ActiveXObject(msxmlhttp[i]);
				} catch (e) {
					A = null;
				}
			}
 			
			if(!A && typeof XMLHttpRequest != "undefined")
				A = new XMLHttpRequest();
			if (!A)
				cfwsajax_debug("Could not create connection object.");
			return A;
		}
		
		var cfwsajax_requests = new Array();
		
		function cfwsajax_cancel() {
			for (var i = 0; i < cfwsajax_requests.length; i++) 
				cfwsajax_requests[i].abort();
		}
		
		function cfwsajax_do_call(func_name, args) {
			var i, x, n;
			var uri;
			var post_data;
			var target_id;
			
			cfwsajax_debug("in cfwsajax_do_call().." + cfwsajax_request_type + "/" + cfwsajax_target_id);
			target_id = cfwsajax_target_id;
			if (typeof(cfwsajax_request_type) == "undefined" || cfwsajax_request_type == "") 
				cfwsajax_request_type = "GET";
			
			uri = "<?php echo $cfwsajax_remote_uri; ?>";
			if (cfwsajax_request_type == "GET") {
			
				if (uri.indexOf("?") == -1) 
					uri += "?rs=" + escape(func_name);
				else
					uri += "&rs=" + escape(func_name);
				uri += "&rst=" + escape(cfwsajax_target_id);
				uri += "&rsrnd=" + new Date().getTime();
				
				for (i = 0; i < args.length-1; i++) 
					uri += "&rsargs[]=" + escape(args[i]);

				post_data = null;
			} 
			else if (cfwsajax_request_type == "POST") {
				post_data = "rs=" + escape(func_name);
				post_data += "&rst=" + escape(cfwsajax_target_id);
				post_data += "&rsrnd=" + new Date().getTime();
				
				for (i = 0; i < args.length-1; i++) 
					post_data = post_data + "&rsargs[]=" + escape(args[i]);
			}
			else {
				alert("Illegal request type: " + cfwsajax_request_type);
			}
			
			x = cfwsajax_init_object();
			if (x == null) {
				if (cfwsajax_failure_redirect != "") {
					location.href = cfwsajax_failure_redirect;
					return false;
				} else {
					cfwsajax_debug("NULL cfwsajax object for user agent:\n" + navigator.userAgent);
					return false;
				}
			} else {
				x.open(cfwsajax_request_type, uri, true);
				// window.open(uri);
				
				cfwsajax_requests[cfwsajax_requests.length] = x;
				
				if (cfwsajax_request_type == "POST") {
					x.setRequestHeader("Method", "POST " + uri + " HTTP/1.1");
					x.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
				}
			
				x.onreadystatechange = function() {
					if (x.readyState != 4) 
						return;

					cfwsajax_debug("received " + x.responseText);
				
					var status;
					var data;
					var txt = x.responseText.replace(/^\s*|\s*$/g,"");
					status = txt.charAt(0);
					data = txt.substring(2);

					if (status == "") {
						// let's just assume this is a pre-response bailout and let it slide for now
					} else if (status == "-") 
						alert("Error: " + data);
					else {
						if (target_id != "") 
							document.getElementById(target_id).innerHTML = eval(data);
						else {
							try {
								var callback;
								var extra_data = false;
								if (typeof args[args.length-1] == "object") {
									callback = args[args.length-1].callback;
									extra_data = args[args.length-1].extra_data;
								} else {
									callback = args[args.length-1];
								}
								callback(eval(data), extra_data);
							} catch (e) {
								cfwsajax_debug("Caught error " + e + ": Could not eval " + data );
							}
						}
					}
				}
			}
			
			cfwsajax_debug(func_name + " uri = " + uri + "/post = " + post_data);
			x.send(post_data);
			cfwsajax_debug(func_name + " waiting..");
			delete x;
			return true;
		}
		
		<?php
		$html = ob_get_contents();
		ob_end_clean();
		return $html;
	}
	
	function cfwsajax_show_common_js() {
		echo cfwsajax_get_common_js();
	}
	
	// javascript escape a value
	function cfwsajax_esc($val)
	{
		$val = str_replace("\\", "\\\\", $val);
		$val = str_replace("\r", "\\r", $val);
		$val = str_replace("\n", "\\n", $val);
		$val = str_replace("'", "\\'", $val);
		return str_replace('"', '\\"', $val);
	}

	function cfwsajax_get_one_stub($func_name) {
		ob_start();	
		?>
		
		// wrapper for <?php echo $func_name; ?>
		
		function x_<?php echo $func_name; ?>() {
			cfwsajax_do_call("<?php echo $func_name; ?>",
				x_<?php echo $func_name; ?>.arguments);
		}
		
		<?php
		$html = ob_get_contents();
		ob_end_clean();
		return $html;
	}
	
	function cfwsajax_show_one_stub($func_name) {
		echo cfwsajax_get_one_stub($func_name);
	}
	
	function cfwsajax_export() {
		global $cfwsajax_export_list;
		
		$n = func_num_args();
		for ($i = 0; $i < $n; $i++) {
			$cfwsajax_export_list[] = func_get_arg($i);
		}
	}
	
	$cfwsajax_js_has_been_shown = 0;
	function cfwsajax_get_javascript()
	{
		global $cfwsajax_js_has_been_shown;
		global $cfwsajax_export_list;
		
		$html = "";
		if (! $cfwsajax_js_has_been_shown) {
			$html .= cfwsajax_get_common_js();
			$cfwsajax_js_has_been_shown = 1;
		}
		foreach ($cfwsajax_export_list as $func) {
			$html .= cfwsajax_get_one_stub($func);
		}
		return $html;
	}
	
	function cfwsajax_show_javascript()
	{
		echo cfwsajax_get_javascript();
	}

	
	$CFWSAJAX_INCLUDED = 1;
}
?>
