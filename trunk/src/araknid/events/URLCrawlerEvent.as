package araknid.events {
	
	import swag.events.SwagEvent;
	
	public class URLCrawlerEvent extends SwagEvent {
		
		/**
		 * Dispatched when a page crawl (retrieval) is fully complete. Links and other information can be extracted after this event.  
		 */
		public static const ONCRAWLCOMPLETE:String="SwagEvent.URLCrawlerEvent.ONCRAWLCOMPLETE";		
		/**
		 * Dispatched while a page crawl (retrieval) is still in progress. Progress variables can be read but page data can't yet. 
		 */
		public static const ONCRAWLPROGRESS:String="SwagEvent.URLCrawlerEvent.ONCRAWLPROGRESS";		
		/**
		 * Dispatched when a page couldn't be crawled (couldn't be fully loaded for some reason).
		 */
		public static const ONCRAWLERROR:String="SwagEvent.URLCrawlerEvent.ONCRAWLERROR";
		
		/**
		 * Error message included only in ONCRAWLERERROR events. 
		 */
		public var errorMessage:String=null;
		
		public function URLCrawlerEvent(eventType:String=null){
			super(eventType);
		}//constructor
		
	}//URLCrawlerEvent class
	
}//package