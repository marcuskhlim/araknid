package araknid {
	
	import araknid.events.URLCrawlerEvent;
	
	import flash.events.DNSResolverEvent;
	import flash.events.ErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLStream;
	import flash.net.dns.AAAARecord;
	import flash.net.dns.ARecord;
	import flash.net.dns.DNSResolver;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagLoader;
	import swag.events.SwagErrorEvent;
	import swag.events.SwagLoaderEvent;
	
	public class URLCrawler {
		
		private static var _crawlers:Vector.<URLCrawler>=new Vector.<URLCrawler>();
		
		private var _crawlURL:String=null;
		private var _loader:SwagLoader;
		private var _loadedBytes:uint=0;
		private var _totalBytes:uint=0;
		private var _dnsResolver:DNSResolver;
		public var sourceDTID:String="";
		
		/**
		 * Contains the full, unparsed and unprocessed content 
		 */
		private var _loadedContent:String=null;
		/**
		 * Contains HTML for processing (with items like comments, etc.) stripped out. 
		 */
		private var _processHTML:String=null;
		private var _IPv4DNSRecord:ARecord=null;
		private var _IPv6DNSRecord:AAAARecord=null;		
		private var _mxRecord:*=null; //Using dynamic evaluation for this	
		private var _dnsResolved:Boolean=false;
		private var _timeout:Timer=null;
		
		public function URLCrawler(crawlURL:String=null) {
			_crawlers.push(this);
			if ((crawlURL==null) || (crawlURL=="")) {
				var event:URLCrawlerEvent=new URLCrawlerEvent(URLCrawlerEvent.ONCRAWLERROR);
				event.errorMessage="Starting URL not provided to URLCrawler constructor.";
				SwagDispatcher.dispatchEvent(event, this);
				this.destroy();
				return;
			}//if			
			this._crawlURL=crawlURL;
			this.setDefaults();		
		}//constructor
		
		public function startCrawl():void {			
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onCrawlLoadComplete, this, this._loader);
			SwagDispatcher.addEventListener(SwagLoaderEvent.DATA, this.onLoadProgress, this, this._loader);
			SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadError, this, this._loader);
			SwagDispatcher.addEventListener(SwagErrorEvent.UNSUPPORTEDOPERATIONERROR, this.onLoadError, this, this._loader);
			SwagDispatcher.addEventListener(SwagErrorEvent.DATAEMPTYERROR, this.onLoadError, this, this._loader);
			SwagDispatcher.addEventListener(SwagErrorEvent.DATAFORMATERROR, this.onLoadError, this, this._loader);
			SwagDispatcher.addEventListener(SwagErrorEvent.ERROR, this.onLoadError, this, this._loader);
			this._dnsResolver=new DNSResolver();
			this._dnsResolver.addEventListener(DNSResolverEvent.LOOKUP, this.onDNSLookup);
			this._dnsResolver.addEventListener(ErrorEvent.ERROR, this.onDNSLookupError);
			var domain:String=this.parseDomain(this._crawlURL);
			if (domain!="") {
				this._dnsResolver.lookup(domain, ARecord);
			//	this._dnsResolver.lookup(domain, AAAARecord);
			//	this._dnsResolver.lookup(domain, SwagSystem.getDefinition("flash.net.dns.MXRecord"));
			} else {
				this._dnsResolved=true;
			}//else
			this._loader.load(null, String);
			this._timeout=new Timer(Settings.crawlTimeout,0);
			this._timeout.addEventListener(TimerEvent.TIMER_COMPLETE, this.onLoadTimeout);
			this._timeout.start();
		}//startCrawl
		
		private function onLoadTimeout(eventObj:TimerEvent):void {
			this.stopTimeoutTimer();
			this.removeListeners();
			var event:URLCrawlerEvent=new URLCrawlerEvent(URLCrawlerEvent.ONCRAWLERROR);
			SwagDispatcher.dispatchEvent(event, this);
		}//onLoadTimeout
		
		private function stopTimeoutTimer():void {
			if (this._timeout!=null) {
				this._timeout.stop();
				this._timeout.removeEventListener(TimerEvent.TIMER_COMPLETE, this.onLoadTimeout);
				this._timeout=null;
			}//if
		}//stopTimeoutTimer
		
		public function onLoadProgress(eventObj:SwagLoaderEvent):void {
			this._loadedBytes=SwagLoader(eventObj.source).bytesLoaded;
			try {
				this._totalBytes=uint(SwagLoader(eventObj.source).responseHeaders["Content-length"]);
			} catch (e:*) {
				this._totalBytes=0
			}//else		
			var event:URLCrawlerEvent=new URLCrawlerEvent(URLCrawlerEvent.ONCRAWLPROGRESS);
			SwagDispatcher.dispatchEvent(event, this);
		}//onLoadProgress
		
		public function onLoadError(eventObj:SwagErrorEvent):void {	
			this.stopTimeoutTimer();
			this.removeListeners();
			var event:URLCrawlerEvent=new URLCrawlerEvent(URLCrawlerEvent.ONCRAWLERROR);
			SwagDispatcher.dispatchEvent(event, this);
		}//onLoadError
		
		public function get loadedBytes():uint {
			return (this._loadedBytes);
		}//get loadedBytes
		
		public function get totalBytes():uint {
			return (this._totalBytes);
		}//get totalBytes
		
		public function get loadedPercent():Number {
			var returnPercent:Number=Math.floor((Number(this._loadedBytes)/Number(this._totalBytes))*100);
			if (returnPercent==Number.POSITIVE_INFINITY) {
				returnPercent=100;
			}//if
			if (returnPercent==Number.NEGATIVE_INFINITY) {
				returnPercent=0;
			}//if
			return (returnPercent);
		}//get loadedPercent
		
		private function onDNSLookup(eventObj:DNSResolverEvent):void {			
			var results:Array=eventObj.resourceRecords;
			for (var item in results) {
				if (results[item] is ARecord) {
					this._IPv4DNSRecord=results[item];					
				}//if
				if (results[item] is AAAARecord) {
					this._IPv6DNSRecord=results[item];					
				}//if
				if (results[item] is SwagSystem.getDefinition("flash.net.dns.MXRecord")) {
					this._mxRecord=results[item];					
				}//if
			}//for
			/*
			if ((this._IPv4DNSRecord!=null) && (this._IPv6DNSRecord!=null) && (this._mxRecord!=null)) {
				this._dnsResolved=true;
				this.onCrawlComplete();
			}//if
			*/
			//Only IPv4 seems reliable at this point
			if (this._IPv4DNSRecord!=null) {
				this._dnsResolved=true;
				this.onCrawlComplete();
			}//if
		}//onDNSLookup
		
		private function onDNSLookupError(eventObj:ErrorEvent):void {
			this._dnsResolved=true;
			this.onCrawlComplete();
		}//onDNSLookupError
		
		public function onCrawlLoadComplete(eventObj:SwagLoaderEvent):void {		
			this._totalBytes=this._loadedBytes;
			this._loadedContent=new String(SwagLoader(eventObj.source).loadedData);
			this._processHTML=this.processHTML(this._loadedContent);
			this.onCrawlComplete();			
		}//onCrawlLoadComplete
		
		private function onCrawlComplete():void {
			//Crawl is complete once both page is retrieved and DNS resolved (or failed)
			if ((this._dnsResolved) && (this._processHTML!=null) && (this._processHTML!="")) {				
				this.removeListeners();			
				var event:URLCrawlerEvent=new URLCrawlerEvent(URLCrawlerEvent.ONCRAWLCOMPLETE);
				SwagDispatcher.dispatchEvent(event, this);				
			}//if
		}//onCrawlComplete
		
		/**
		 * Processes an HTML string by stripping out extraneous/non-parsable elements like comments, etc. 
		 *  
		 * @param inputHTML The raw input HTML to process.
		 * 
		 * @return The returned HTML containing only valid, active HTML elements. 
		 * 
		 */
		public function processHTML(inputHTML:String):String {
			//HTML comment (<!-- -->) pattern to remove
			//var commentsRegExp:RegExp=new RegExp("\<![ \r\n\t]*(--([^\-]|[\r\n]|-[^\-])*--[ \r\n\t]*)\>" ,"gm");
			var expressionList:Array=Settings.getRegExps("striphtmlcomments");
			if ((expressionList==null)  || (expressionList.length==0)) {
				return (this._loadedContent);
			}//if
			for (var count:uint=0; count<expressionList.length; count++) {
				var currentExp:Object=expressionList[count] as Object;
				this._loadedContent=this._loadedContent.replace(currentExp.regex,currentExp.options)
			}//for
			return (this._loadedContent);
		}//processHTML
		
		//Content parsing / extraction routines
		
		public function parseDomain(url:String):String {
			if (url.indexOf("://")<0) {
				return ("");
			}//if
			var section1:String=url.split("://")[1] as String; //remove everything before domain
			var section2:String=section1.split("/")[0] as String; //remove everything after domain
			return (section2);
		}//parseDomain
		
		/**
		 * Returns a URL containing the full relative path (until the final slash), of the specified URL.
		 * 
		 * @param url The source URL to parse.
		 *  
		 * @return The full relative URL, until the final forward slash, of the input URL. Useful for forming
		 * complete URLs out of partial/relative ones. 
		 * 
		 */
		public function parseRelativeAddress(url:String):String {
			if (url.indexOf("://")<0) {
				return ("");
			}//if		
			var finalSlashIndex:int=url.lastIndexOf("/");
			var urlString:String=url.substring(0, finalSlashIndex);
			return (urlString);
		}//parseRelativeAddress
		
		/**
		 * @return An array of any valid HTML <code><a></code> (link) tags. The returned indexed array
		 * includes just the URL (HREF) portion of the tag.		 
		 */
		public function parseATags():Array {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if			
			var linkExps:Array=Settings.getRegExps("atags");
			if ((linkExps==null) || (linkExps.length==0)) {
				return (null);
			}//if
			var returnLinks:Array=new Array();
			for (var expCount:uint=0; expCount<linkExps.length; expCount++) {
				var currentExp:Object=linkExps[expCount] as Object;
				var linkExp:RegExp=new RegExp(currentExp.regex, currentExp.options);
				var extractedHREFs:Array=this._processHTML.match(linkExp);				
				for (var count:uint=0; count<extractedHREFs.length; count++) {					
					var urlExps:Array=Settings.getRegExps("url");
					if ((urlExps==null) || (urlExps.length==0)) {
						return (null);
					}//if
					for (var expCount2:uint=0; expCount2<urlExps.length; expCount2++) {
						var urlExpObj:Object=urlExps[expCount2] as Object;
						var urlExp:RegExp=new RegExp(urlExpObj.regex, urlExpObj.options);					
						try {
							var currentHREF:String=extractedHREFs[count] as String;				
							var ref:String=currentHREF.match(urlExp)[1];
							ref=ref.split("\"").join("").split("'").join(""); //Remove final quotes
							var tempRef:String=ref.toLowerCase();
							//Relative link, so prepend with full address...
							if (tempRef.indexOf("://")<0) {
								if (ref.substr(0,1)!="/") {
									ref="/"+ref; //Add additional slash in front in case there isn't one
								}//if
								ref=this.parseRelativeAddress(this._crawlURL)+ref;
							}//if
							returnLinks.push(ref);
						} catch (e:*) {				
						}//catch
					}//for
				}//for
			}//for
			return (returnLinks);			
		}//parseATags
		
		/**		 
		 * @return An array of HTTP/HTTPS links, including any GET query data, anywhere in the HTML document.
		 * Note that this is potentially a more extensive set than returned by the <code>parseATags</code> method. 
		 */
		public function parseLinks():Array {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if
			var urlExps:Array=Settings.getRegExps("urls");
			if ((urlExps==null) || (urlExps.length==0)) {
				return (null);
			}//if
			for (var expCount:uint=0; expCount<urlExps.length; expCount++) {
				var currentExp:Object=urlExps[expCount] as Object;
				//Note the dash in the regular expression has to come after the "or" (pipe) at the end otherwise it doesn't work for some reason!
				var linkExp:RegExp=new RegExp(currentExp.regex, currentExp.options);			
				var extractedLinks:Array=this._processHTML.match(linkExp);
				var condensed:Array=new Array();
				//Remove duplicates
				var linkLength:uint=extractedLinks.length;
				var dict:Dictionary=new Dictionary();
				for (var count:uint=0;count<linkLength;count++) {
					try {
						var currentLink:String=extractedLinks[count] as String;
						if (!dict[currentLink]) {
							dict[currentLink]=true;
							condensed.push(currentLink);
						}//if
					} catch (e:*) {					
					}//catch
				}//for
			}//for
			return (condensed);
		}//parseLinks	
		
		/**		 
		 * @return An array of JavaScript tags, both inline and loaded (using "src" attribute). Additional parsing may be
		 * required to extract inline JavaScript or filepaths. 
		 */
		public function parseJavaScript():Array {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if			
			var jsExp:RegExp=new RegExp("<script.*>[.\n]*<\/script>","gim");			
			var extractedJS:Array=this._processHTML.match(jsExp);			
			return (extractedJS);
		}//parseJavaScript
		
		/**		 
		 * @return An array of JavaScript tags, both inline and loaded (using "src" attribute). Additional parsing may be
		 * required to extract inline JavaScript or filepaths. 
		 */
		public function parseStyles():Array {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if					
			var styleExp:RegExp=new RegExp("<style.*>.*<\/style>","gimsx");
			var extractedStyles:Array=this._processHTML.match(styleExp);			
			var loadedStyleExp:RegExp=new RegExp("<link.*rel=[\\x22\\x27]stylesheet[\\x22\\x27].*\/>","gim");			
			extractedStyles=extractedStyles.concat(this._processHTML.match(loadedStyleExp));		
			return (extractedStyles);
		}//parseStyles
		
		/**		 
		 * @return An array of keywords from the keywords meta tag. Returned array will be empty if tag is empty or doesn't exist.
		 */
		public function parseKeyWords():Array {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if
			var keyWordExp:RegExp=new RegExp("<meta.*name=.*[\\x22\\x27]keywords[\\x22\\x27].*>","gim");			
			var keywordNodes:Array=this._processHTML.match(keyWordExp);	
			var contentExp:RegExp=new RegExp("content=[\\x22\\x27].*[\\x22\\x27]","i");
			var contentListExp:RegExp=new RegExp("[\\x22\\x27].*[\\x22\\x27]","i");
			var keywords:Array=new Array();
			//If more than one valid meta node exists, only process the last one
			var currentKeywordNode:String=keywordNodes[keywordNodes.length-1] as String;
			try {
				var parsedList:String=String(currentKeywordNode.match(contentExp)[0].match(contentListExp)[0]).split("\"").join("").split("'").join("");
				keywords=keywords.concat(parsedList.split(","));
			} catch (e:*) {					
			}//catch			
			return (keywords);			
		}//parseKeyWords
		
		/**		 
		 * @return The content-type meta tag of the loaded document, or an empty string if not found/defined.
		 */
		public function parseContentType():String {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if
			var returnContentType:String=new String();
			try {
				var contentTypeExp:RegExp=new RegExp("<meta.*http\-equiv.*[\\x22\\x27]content\-type[\\x22\\x27].*>","gim");			
				var contentTypeNodes:Array=this._processHTML.match(contentTypeExp);
				var contentTypeNode:String=contentTypeNodes[contentTypeNodes.length-1];
				var contentExp:RegExp=new RegExp("content=[\\x22\\x27].*[\\x22\\x27]","i");
				var contentDefExp:RegExp=new RegExp("[\\x22\\x27].*[\\x22\\x27]","i");
				returnContentType=String(contentTypeNode.match(contentExp)[0].match(contentDefExp)[0]).split("\"").join("").split("'").join("");
			} catch (e:*) {				
			}//catch			
			return (returnContentType);			
		}//parseContentType
		
		/**		 
		 * @return The description meta tag of the loaded document, or an empty string if not found/defined.
		 */
		public function parseDescription():String {
			if ((this._processHTML==null) || (this._processHTML=="")) {
				return (null);
			}//if
			var returnDescription:String=new String();
			try {
				var descriptionTypeExp:RegExp=new RegExp("<meta.*name=[\\x22\\x27]description[\\x22\\x27].*>","gim");			
				var descriptionTypeNodes:Array=this._processHTML.match(descriptionTypeExp);
				var descriptionTypeNode:String=descriptionTypeNodes[descriptionTypeNodes.length-1];				
				var descriptionContentExp:RegExp=new RegExp("content=[\\x22\\x27].*[\\x22\\x27]","i");
				var descriptionExp:RegExp=new RegExp("[\\x22\\x27].*[\\x22\\x27]","i");
				returnDescription=String(descriptionTypeNode.match(descriptionContentExp)[0].match(descriptionExp)[0]).split("\"").join("").split("'").join("");
			} catch (e:*) {				
			}//catch			
			return (returnDescription);			
		}//parseDescription
		
		public function get crawlURL():String {
			return (this._crawlURL);
		}//get crawlURL
		
		public function get loadedContent():String {
			return (this._loadedContent);
		}//get loadedContent
		
		public function get IPv4Address():String {
			try {
				return (this._IPv4DNSRecord.address);
			} catch (e:*) {
				return ("");
			}//catch
			return ("");
		}//get IPv4Address
		
		public function get IPv6Address():String {
			try {
				return (this._IPv6DNSRecord.address);
			} catch (e:*) {
				return ("");
			}//catch
			return ("");
		}//get IPv6Address
		
		public function get MXRecord():String {
			try {
				return (this._mxRecord.exchange);
			} catch (e:*) {
				return ("");
			}//catch
			return ("");
		}//get MXRecord
		
		private function setDefaults():void {
			this._loader=new SwagLoader(this._crawlURL);
		}//setDefaults
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onCrawlLoadComplete, this._loader);
			SwagDispatcher.removeEventListener(SwagLoaderEvent.DATA, this.onLoadProgress, this._loader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadError, this._loader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.UNSUPPORTEDOPERATIONERROR, this.onLoadError, this._loader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.DATAEMPTYERROR, this.onLoadError, this._loader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.DATAFORMATERROR, this.onLoadError, this._loader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.ERROR, this.onLoadError, this._loader);
			this._dnsResolver.removeEventListener(DNSResolverEvent.LOOKUP, this.onDNSLookup);
			this._dnsResolver.removeEventListener(ErrorEvent.ERROR, this.onDNSLookupError);
		}//removeListeners
		
		public function destroy():void {
			this.removeListeners();
			this.stopTimeoutTimer();
			this._loader=null;
			this._crawlURL=null;
			var compacted:Vector.<URLCrawler>=new Vector.<URLCrawler>();
			for (var count:uint=0; count<_crawlers.length; count++) {
				if (_crawlers[count]!=this) {
					compacted.push(_crawlers[count]);
				}//if
			}//for
			_crawlers=compacted;
		}//destroy
		
	}//URLCrawler class
	
}//package