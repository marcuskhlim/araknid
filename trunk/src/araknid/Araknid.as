package araknid {
	
	import araknid.Database;
	import araknid.Settings;
	import araknid.URLCrawler;
	import araknid.events.SettingsEvent;
	import araknid.events.URLCrawlerEvent;
	
	import fl.controls.NumericStepper;
	import fl.controls.TextArea;
	
	import flash.desktop.NativeProcess;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagTime;
	import swag.events.SwagTimeEvent;
	
	public class Araknid extends Sprite {
		
		public var dbFileField:TextField;
		public var currentCrawlURLField:TextField;
		public var lastCrawlContentsField:TextArea;
		public var bytesLoadedField:TextField;
		public var nextCrawlTimeField:TextField;
		public var dbFileSizeField:TextField;
		public var crawlDelaySetNS:NumericStepper;
		public var linkButton:SimpleButton;
		public var databaseButton:SimpleButton;
		public var playButton:SimpleButton;
		public var pauseButton:SimpleButton;
		
		private var _crawler:URLCrawler;	
		private var _db:Database;
		private var _currentDTID:String="";
		private var _paused:Boolean=true;
		
		private var _countdownTimer:SwagTime;
		
		public function Araknid() {	
			this.crawlDelaySetNS.addEventListener(Event.ACTIVATE, this.updateCrawlDelayNS);		
			this.setDefaults();
		}//constructor
		
		private function onFileSaveSelect(eventObj:Event):void {			
			Settings.dbFileURL=eventObj.target.nativePath;
			this.openDatabase(true);
		}//onFileSaveSelect
		
		private function openDatabase(isNew:Boolean=false):void {			
			this.dbFileField.text=Settings.dbFileURL;
			this._db=new Database();				
			if (isNew) {
				this._db.addURLToCrawlQueue(Settings.startCrawlURL);
			}//if			
			this.crawl();
		}//openDatabase
		
		private function crawl(eventObj:SwagTimeEvent=null):void {	
			if (this._countdownTimer!=null) {
				SwagDispatcher.removeEventListener(SwagTimeEvent.ENDCOUNTDOWN, this.crawl, this._countdownTimer);
				SwagDispatcher.removeEventListener(SwagTimeEvent.ONCOUNTDOWN, this.updateCrawlTime, this._countdownTimer);
				this._countdownTimer=null
			}//if
			this.playButton.visible=false;
			this.pauseButton.visible=true;
			this._paused=false;
			this.bytesLoadedField.text="0 bytes (0%)";
			var nextURL:String=this._db.nextQueuedCrawlURL;
			if (nextURL==null) {
				nextURL=Settings.startCrawlURL;
			}//if
			this.currentCrawlURLField.text=nextURL;
			this.nextCrawlTimeField.text="Now";
			this._crawler=new URLCrawler(nextURL);
			this._crawler.sourceDTID=this._db.nextQueuedCrawlDTID;
			SwagDispatcher.addEventListener(URLCrawlerEvent.ONCRAWLCOMPLETE, this.onCrawlDone, this, this._crawler);
			SwagDispatcher.addEventListener(URLCrawlerEvent.ONCRAWLERROR, this.onCrawlError, this, this._crawler);
			SwagDispatcher.addEventListener(URLCrawlerEvent.ONCRAWLPROGRESS, this.onCrawlProgress, this, this._crawler);
			this.lastCrawlContentsField.text="";
			this._crawler.startCrawl();			
		}//crawl
		
		public function onCrawlDone(eventObj:URLCrawlerEvent):void {	
			SwagDispatcher.removeEventListener(URLCrawlerEvent.ONCRAWLCOMPLETE, this.onCrawlDone, this._crawler);
			SwagDispatcher.removeEventListener(URLCrawlerEvent.ONCRAWLERROR, this.onCrawlError, this._crawler);
			SwagDispatcher.removeEventListener(URLCrawlerEvent.ONCRAWLPROGRESS, this.onCrawlProgress,  this._crawler);
			this.parseCrawledData(this._crawler);
		}//onCrawlDone
		
		public function onCrawlError(eventObj:URLCrawlerEvent):void {
			this.bytesLoadedField.text="Error loading";
			this._db.removeQueueCrawlURL(URLCrawler(eventObj.source).crawlURL);
			SwagDispatcher.removeEventListener(URLCrawlerEvent.ONCRAWLCOMPLETE, this.onCrawlDone, this._crawler);
			SwagDispatcher.removeEventListener(URLCrawlerEvent.ONCRAWLERROR, this.onCrawlError, this._crawler);
			SwagDispatcher.removeEventListener(URLCrawlerEvent.ONCRAWLPROGRESS, this.onCrawlProgress,  this._crawler);
			this._crawler.destroy();
			this._crawler=null;
			this.startNextCrawl();
		}//onCrawlError
		
		public function onCrawlProgress(eventObj:URLCrawlerEvent):void {
			this.bytesLoadedField.text=String(URLCrawler(eventObj.source).loadedBytes)+" bytes ("+URLCrawler(eventObj.source).loadedPercent+"%)";			
		}//onCrawlError
		
		private function parseCrawledData(crawler:URLCrawler):void {
			this._db.addCompletedCrawl(crawler, this.startNextCrawl);
		}//parseCrawledData
		
		private function startNextCrawl():void {
			if (this._paused) {
				return;
			}//if	
			for (var count:uint=0; count<this._db.extractedLinks.length; count++) {
				var currentLink:String=this._db.extractedLinks[count] as String;
				this.lastCrawlContentsField.appendText(currentLink+"\n");
			}//for
			this._db.resetCrawlLink();
			var dbFile:File=new File();
			dbFile.nativePath=this.dbFileField.text;
			var size:Number=(Math.floor(dbFile.size/10000))/100;
			var fileSizeStr:String=String(size)+"Mb";
			this.dbFileSizeField.text=fileSizeStr;
			try {
				this._db.removeQueueCrawlURL(this._crawler.crawlURL);
				this._crawler.destroy();
			} catch (e:*) {				
			}//catch
			this._crawler=null;	
			this.playButton.visible=false;
			this.pauseButton.visible=true;
			if (crawlDelaySetNS.value!=Settings.crawlDelay) {
				Settings.crawlDelay=crawlDelaySetNS.value;
			}//if
			//Add 1 since countdown starts at 1 less (0 is counted as final value)
			this._countdownTimer=new SwagTime("00:00:"+String(Settings.crawlDelay+1));
			SwagDispatcher.addEventListener(SwagTimeEvent.ENDCOUNTDOWN, this.crawl, this, this._countdownTimer);
			SwagDispatcher.addEventListener(SwagTimeEvent.ONCOUNTDOWN, this.updateCrawlTime, this, this._countdownTimer);
			this._countdownTimer.startCountDown();
		}//startNextCrawl
		
		public function updateCrawlTime(eventObj:SwagTimeEvent):void {
			this.nextCrawlTimeField.text=SwagTime(eventObj.source).getTimeString("s")+" seconds";
		}//updateCrawlTime
		
		private function onLinkClick(eventObj:MouseEvent):void {
			var request:URLRequest=new URLRequest(this.currentCrawlURLField.text);
			navigateToURL(request, "_blank");
		}//onLinkClick
		
		private function onOpenDBClick(eventObj:MouseEvent):void {
			var dbFile:File = new File();
			dbFile.nativePath=this.dbFileField.text;
			dbFile.openWithDefaultApplication();
		}//onOpenDBClick
		
		private function onPlayClick(eventObj:MouseEvent):void {
			this._paused=false;
			this.playButton.visible=false;
			this.pauseButton.visible=true;
			if (this._countdownTimer!=null) {
				this._countdownTimer.startCountDown();
			} else {
				this.crawl();
			}//else
		}//onPlayClick
		
		private function onPauseClick(eventObj:MouseEvent):void {
			this._paused=true;
			this.playButton.visible=true;
			this.pauseButton.visible=false;
			if (this._countdownTimer!=null) {
				this._countdownTimer.stopCountDown();
			}//if
		}//onPauseClick
		
		private function updateCrawlDelayNS(eventObj:Event):void {
			this.crawlDelaySetNS.removeEventListener(Event.ADDED_TO_STAGE, this.updateCrawlDelayNS);
			crawlDelaySetNS.value=Settings.crawlDelay;
		}//updateCrawlDelayNS
		
		public function initialize(... args):void {
			SwagDispatcher.removeEventListener(SettingsEvent.ONSETTINGSLOADED, this.initialize, Settings);
			this.playButton.visible=true;
			this.pauseButton.visible=false;
			if (Settings.dbFileURL==null) {
				//File not set yet (probably the first time running Araknid)
				var fileRef:File=new File();
				fileRef.addEventListener(Event.SELECT, this.onFileSaveSelect);
				fileRef.browseForSave("Save SQLite database file as...");
			} else{
				fileRef=new File(Settings.dbFileURL);
				if (!fileRef.exists) {
					//File doesn't exist (probably deleted)
					fileRef=new File();
					fileRef.addEventListener(Event.SELECT, this.onFileSaveSelect);
					fileRef.browseForSave("Save SQLite database file as...");
				} else {
					this.openDatabase();
				}//else
			}//else	
			this.linkButton.addEventListener(MouseEvent.CLICK, this.onLinkClick);
			this.databaseButton.addEventListener(MouseEvent.CLICK, this.onOpenDBClick);
			this.playButton.addEventListener(MouseEvent.CLICK, this.onPlayClick);
			this.pauseButton.addEventListener(MouseEvent.CLICK, this.onPauseClick);	
		}//initialize
		
		private function setDefaults():void {
			SwagDispatcher.addEventListener(SettingsEvent.ONSETTINGSLOADED, this.initialize, this, Settings);
			Settings.loadConfig(); //Load default config XML file
		}//setDefaults
		
	}//Araknid class
	
}//package