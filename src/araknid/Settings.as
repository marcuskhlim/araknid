package araknid {
	
	import araknid.events.SettingsEvent;
	
	import flash.net.SharedObject;
	
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagLoader;
	import swag.events.SwagLoaderEvent;
	
	public class Settings {
		
		public static const startCrawlURL:String="http://www.dmoz.org/"; //Good place to begin crawling -- feel free to replace with your own!
		public static const configFileURL:String="config.xml";
		
		private static var _configLoader:SwagLoader;
		private static var _configData:XML=null;
		
		//SQLite table settings
		public static const completedCrawlTableName:String="complete";
		public static const queuedCrawlTableName:String="queued";
		
		public static const crawlTimeout:Number=15000; //15 second timeout
		
		public static function get dbFileURL():String {
			try {
				var urlStr:*=getStoredSetting("dbFileURL");
			} catch (err:*) {
				var returnStr:String=null;
			}//catch
			if ((urlStr==undefined) || (urlStr==null)) {
				returnStr=null;
			} else {
				returnStr=new String(urlStr);
			}//else
			return (returnStr);
		}//get dbFileURL
		
		public static function loadConfig(configURL:String=null):void {
			if ((configURL==null) || (configURL=="")) {
				configURL=configFileURL;
			}//if
			_configLoader=new SwagLoader();
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onLoadConfig, Settings, _configLoader);
			_configLoader.load(configURL, XML);
		}//loadConfig
		
		public static function onLoadConfig(eventObj:SwagLoaderEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadConfig, _configLoader);
			//Remove the loader -- just keep the data
			_configData=new XML(String(_configLoader.loadedData));
			_configLoader=null;
			SwagDispatcher.dispatchEvent(new SettingsEvent(SettingsEvent.ONSETTINGSLOADED), Settings);
		}//onLoadConfig
		
		public static function get settingsData():XML {
			return (_configData);
		}//get settingsData
		
		public static function getSettingNode(settingName:String):XML {
			if (_configData==null) {
				return (null);
			}//if
			var returnValue:String=null;
			var childNodes:XMLList=_configData.child(settingName) as XMLList;
			for (var count:uint=0; count<childNodes.length(); count++) {
				var currentNode:XML=childNodes[count] as XML;
				if (String(currentNode.localName())==settingName) {
					return (currentNode);
				}//if
			}//for
			return (null);
		}//getSetting
		
		public static function getRegExCategory(categoryName:String):XMLList {
			if ((categoryName==null) || (categoryName=="")) {
				return (null);
			}//if
			var regExNode:XML=getSettingNode("regex");
			if (regExNode==null) {
				return (null);
			}//if
			var categoryNodes:XMLList=regExNode.children();
			for (var count:uint=0; count<categoryNodes.length(); count++) {
				var currentNode:XML=categoryNodes[count] as XML;
				if (currentNode.@name==categoryName) {
					return (currentNode.children());
				}//if
			}//for
			return (null);
		}//getRegExCategory
		
		/**
		 * Returns an array of regular expressions and options for a specified category
		 * listed in the configuration XML data.
		 *  
		 * @param categoryName The category name for which to return a list of regular expressions.
		 * 
		 * @return A numbered array of objects, each containing properties "regex" with the regular
		 * expression for the category, and "options" with the regular expression options. <em>null</em>
		 * is returned if no associated category name can be found.
		 * 
		 */
		public static function getRegExps(categoryName:String):Array {
			if ((categoryName==null) || (categoryName=="")) {
				return (null);
			}//if
			var returnArr:Array=new Array();
			var expressions:XMLList=getRegExCategory(categoryName);
			if (expressions==null) {
				return (null);
			}//if
			for (var count:uint=0; count<expressions.length(); count++) {
				var currentExp:XML=expressions[count] as XML;
				var options:String=new String(currentExp.@options);
				var expression:String=new String(currentExp.children().toString());
				var expObj:Object=new Object();
				expObj.regex=expression;
				expObj.options=options;
				returnArr.push(expObj);
			}//for
			return (returnArr);
		}//getRegExps
		
		public static function set dbFileURL(urlSet:String):void {
			setStoredSetting("dbFileURL", urlSet); 
		}//set dbFileURL
		
		public static function get crawlDelay():Number {
			try {
				var delayVal:Number=getStoredSetting("crawlDelay");
				return (delayVal);
			} catch (e:*) {
				return (7);
			}//catch
			return (7);
		}//get crawlDelay
		
		public static function set crawlDelay(delaySet:Number):void {
			setStoredSetting("crawlDelay", delaySet); 
		}//set crawlDelay
		
		private static function getStoredSetting(settingName:String):* {
			var so:SharedObject=SharedObject.getLocal("Araknid");			
			return (so.data[settingName]);
		}//getStoredSetting
		
		private static function setStoredSetting(settingName:String, value:*):void {
			var so:SharedObject=SharedObject.getLocal("Araknid");			
			so.data[settingName]=value;
			so.flush();
		}//setStoredSetting
		
	}//Setting class
	
}//package