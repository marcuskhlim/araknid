package araknid {
	
	import araknid.Settings;
	import araknid.URLCrawler;
	import araknid.events.URLCrawlerEvent;
	
	import flash.data.SQLResult;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SQLiteDatabase;
	import swag.core.instances.SwagDate;
	import swag.core.instances.SwagTime;
	import swag.events.SQLiteDatabaseEvent;
	
	public class Database {
		
		public static const _dbPath:String="AraknidDB.sqlite";
		
		private var _onAddCrawlCB:Function=null;		
		private var _db:SQLiteDatabase;
		private var _currentCrawler:URLCrawler;
		private var _currentDTID:String;
		private var _crawlCounter:uint=0;
		private var _extractedLinks:Array=new Array();
		
		public function Database() {
			this.setDefaults();			
		}//constructor
		
		public function get nextQueuedCrawlURL():String {
			var query:String="SELECT * FROM `"+Settings.queuedCrawlTableName+"` LIMIT 1;";						
			var result:SQLResult=this._db.executeQuery(query);
			try {
				var returnURL:String=new String(result.data[0].url);
				return (returnURL);
			} catch (e:*) {
				return (null);
			}//catch			
			return (null);
		}//get nextQueuedCrawlURL
		
		public function get nextQueuedCrawlDTID():String {
			var query:String="SELECT * FROM `"+Settings.queuedCrawlTableName+"` LIMIT 1;";						
			var result:SQLResult=this._db.executeQuery(query);
			try {
				var returnURL:String=new String(result.data[0].SourceDTID);
				return (returnURL);
			} catch (e:*) {
				return ("");
			}//catch			
			return ("");
		}//get nextQueuedCrawlDTID
		
		public function removeQueueCrawlURL(url:String):SQLResult {
			var query:String="DELETE FROM `"+Settings.queuedCrawlTableName+"` WHERE url='"+url+"';";	
			var result:SQLResult=this._db.executeQuery(query);	
			return (result);
		}//removeQueueCrawlURL
		
		public function crawlURLQueued(url:String):Boolean {
			var query:String="SELECT * FROM `"+Settings.queuedCrawlTableName+"` WHERE url='"+url+"' LIMIT 1;";						
			var result:SQLResult=this._db.executeQuery(query);
			try {
				if (result.data.length>0) {
					return (true);
				}//if
			} catch (e:*) {
				return (false);
			}//catch			
			return (false);
		}//crawlURLQueued
		
		public function crawlURLCompleted(url:String):Boolean {
			var query:String="SELECT * FROM `"+Settings.completedCrawlTableName+"` WHERE url='"+url+"' LIMIT 1;";						
			var result:SQLResult=this._db.executeQuery(query);
			try {
				if (result.data.length>0) {
					return (true);
				}//if
			} catch (e:*) {
				return (false);
			}//catch			
			return (false);
		}//crawlURLCompleted
		
		/*
		SQL to trim duplicates (not working, but a start!):
		DELETE FROM `complete` WHERE `domain` NOT IN (SELECT MIN (`domain`) FROM `complete` GROUP BY `domain`)
		*/
		
		
		public function addURLToCrawlQueue(url:String, sourceDTID:String=""):SQLResult {
			//if (this.crawlURLQueued(url) || this.crawlURLCompleted(url)) {
			//	return (null);
			//}//if
			var currentTime:SwagTime=new SwagTime();
			var dateObj:Date=new Date();
			currentTime.hours=uint(dateObj.hours);
			currentTime.minutes=uint(dateObj.minutes);
			currentTime.seconds=uint(dateObj.seconds);
			currentTime.milliseconds=uint(dateObj.milliseconds);
			var currentDate:SwagDate=new SwagDate();
			var dateString:String=currentDate.dayOfWeekName+", "+SwagDate.getMonthName(currentDate.month)+" ";
			dateString+=String(currentDate.day)+", "+String(currentDate.year);
			var query:String="INSERT INTO `"+Settings.queuedCrawlTableName+"` (`url`, `SourceDTID`, `Time`, `Date`) ";
			query+="VALUES ('"+url+"', '"+sourceDTID+"', '"+currentTime.getTimeString("H:M:S.l")+"', '"+dateString+"');"										
			var result:SQLResult=this._db.executeQuery(query);			
			return (result);
		}//addURLToCrawlQueue
		
		public function addCompletedCrawl(crawler:URLCrawler, callback:Function=null):void {
			//Added callback to make database queries more asynchronous...still not perfect, but improves performance (for now).
			if (callback==null) {
				trace ("Database.addCompletedCrawl - callback parameter can't be null!");
				return;
			}//if			
			this._onAddCrawlCB=callback;
			//Step 1: Add raw crawled data...
			var currentTime:SwagTime=new SwagTime();
			var dateObj:Date=new Date();
			currentTime.hours=uint(dateObj.hours);
			currentTime.minutes=uint(dateObj.minutes);
			currentTime.seconds=uint(dateObj.seconds);
			currentTime.milliseconds=uint(dateObj.milliseconds);
			var currentDate:SwagDate=new SwagDate();
			var DTID:String=this.createDTID();
			var sourceDTID:String=crawler.sourceDTID;
			var dateString:String=currentDate.dayOfWeekName+", "+SwagDate.getMonthName(currentDate.month)+" ";
			dateString+=String(currentDate.day)+", "+String(currentDate.year);
			var query:String="INSERT INTO `"+Settings.completedCrawlTableName+"` (`url`, `file`, `domain`, `IPv4`, `content`, `DTID`, ";
			query+="`SourceDTID`, `Date`, `Time`) VALUES (";
			query+="'"+crawler.crawlURL+"', '', '"+crawler.parseDomain(crawler.crawlURL)+"', '"+crawler.IPv4Address+"', ";
			query+="@content, '"+DTID+"', '"+sourceDTID+"', '"+dateString+"', ";
			query+="'"+currentTime.getTimeString("H:M:S.l")+"');";
			var paramObject:Object=new Object();
			//Use a parameter for this to retain data integrity
			paramObject["@content"]=crawler.loadedContent;
			this._currentCrawler=crawler;
			this._currentDTID=DTID;
			this._crawlCounter=0;
			SwagDispatcher.addEventListener(SQLiteDatabaseEvent.ONRESULT, this.addCompletedCrawlStep2, this);		
			var result:SQLResult=this._db.executeQuery(query, paramObject, true);	
		}//addCompletedCrawl
		
		public function addCompletedCrawlStep2(eventObj:SQLiteDatabaseEvent):void {	
			this._extractedLinks=new Array();
			SwagDispatcher.removeEventListener(SQLiteDatabaseEvent.ONRESULT, this.addCompletedCrawlStep2, eventObj.source);
			//Step 2: Add extracted URLs to queue...			
			var linkList:Array=this._currentCrawler.parseLinks(); // Method 1			
			for (var count:uint=0; count<linkList.length; count++) {
				var currentLink:String=linkList[count] as String;	
				this._extractedLinks.push(currentLink);
				this.addURLToCrawlQueue(currentLink, this._currentDTID);
			}//for		
		//	var AList:Array=this._currentCrawler.parseATags(); //Method 2			
		//	for (count=0; count<AList.length; count++) {
		//		currentLink=AList[count] as String;	
		//		this._extractedLinks.push(currentLink);
		//		this.addURLToCrawlQueue(currentLink, this._currentDTID);
		//	}//for
			this._currentCrawler=null;
			if (this._onAddCrawlCB!=null) {
				this._onAddCrawlCB();
			}//if
			this._onAddCrawlCB=null;
		}//addCompletedCrawlStep2
		
		public function resetCrawlLink():void {
			this._extractedLinks=new Array();
		}//resetCrawlLink
				
		
		/**
		 * @return A unique Date-Time ID stamp used to uniquely identify database entries. Format is: YYYYDDMM-HHMMSS-(random hex string)	 
		 * 		where YYYYDDMM is the 0-padded current date, HHMMSSmmm is the 0-padded current time, and the hex string is simply a 
		 * 		hex-encoded random numeric value (Math.random()*1000000)
		 */
		public function createDTID():String {
			var returnDTID:String=new String();
			var dateObj:SwagDate=new SwagDate();
			returnDTID=String(dateObj.dateIndex);
			var timeObj:SwagTime=new SwagTime();
			returnDTID+="-"+timeObj.getTimeString("HMSl");			
			returnDTID+="-"+Number(Math.floor(Math.random()*1000000)).toString(16);
			return (returnDTID);
		}//createDTID
		
		public function get filePath():String {
			return (this._db.filePath);
		}//get filePath
		
		public function get extractedLinks():Array {
			return (this._extractedLinks);
		}//get extractedLinks
		
		private function setDefaults():void {
			this._db=new SQLiteDatabase(Settings.dbFileURL, true);		
			var completeTableFields:Array=new Array();
			completeTableFields["url"]="VARCHAR"; //Full URL of content (HTML, XML, script, style, etc.)
			completeTableFields["file"]="VARCHAR"; //Associated file (usually asset) stored on disk; empty if none
			completeTableFields["domain"]="VARCHAR"; //Domain portion of URL
			completeTableFields["IPv4"]="VARCHAR"; //Resolved IPv4 address from DNS			
			completeTableFields["content"]="VARCHAR"; //Raw content			
			completeTableFields["DTID"]="VARCHAR"; //Date-Time ID stamp
			completeTableFields["SourceDTID"]="VARCHAR"; //Source (parent or owner) Date-Time ID stamp
			completeTableFields["Date"]="VARCHAR"; //Date that record was added
			completeTableFields["Time"]="VARCHAR"; //Time that record was added
			var queuedTableFields:Array=new Array();
			queuedTableFields["url"]="VARCHAR";
			queuedTableFields["SourceDTID"]="VARCHAR";
			queuedTableFields["Date"]="VARCHAR"; //Date that record was added
			queuedTableFields["Time"]="VARCHAR"; //Time that record was added
			this._db.createTable(Settings.completedCrawlTableName,completeTableFields);
			this._db.createTable(Settings.queuedCrawlTableName,queuedTableFields);			
		}//setDefaults
		
	}//Database class
	
}//package