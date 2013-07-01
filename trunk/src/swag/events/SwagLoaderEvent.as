package swag.events {
	
	import swag.events.SwagEvent;
	import swag.interfaces.events.ISwagLoaderEvent;
	
	public class SwagLoaderEvent extends SwagEvent implements ISwagLoaderEvent	{
		
		/**
		 * This event type is dispatched just before the associated <code>SwagLoader</code> object begins
		 * a load or send operation. 
		 */
		public static const START:String="SwagEvent.SwagLoaderEvent.START";
		/**
		 * This event type is dispatched whenever the associated <code>SwagLoader</code> receives or sends data.
		 */
		public static const DATA:String = "SwagEvent.SwagLoaderEvent.DATA";
		/**
		 * This event type is dispatched whenever the HTTP header data of a <code>SwagLoader</code> request is received.
		 */
		public static const HEADER:String="SwagEvent.SwagLoaderEvent.HEADER";
		/**
		 * This event type is dispatched when the associated <code>SwagLoader</code> completes its load or send
		 * operation.
		 * <p>Any loaded data at this point will have been converted to the desired format and may be fully read.</p>
		 */
		public static const COMPLETE:String = "SwagEvent.SwagLoaderEvent.COMPLETE";
		
		/*
		 * The following three values store the transfer information for the following up/download.
		 * If no load is active, these values will all default to 0.
		 */
		public var bytesLoaded:Number = 0;
		public var bytesTotal:Number = 0;
		public var bytesPercent:Number = 0;
		public var BPS:Number = 0; //Bytes per second (sampled on ever load progress event)
		public var msecsElapsed:Number = 0;
		public var msecsRemainEst:Number = 0;
		
		/**
		 * The default constructor for the class.
		 *  
		 * @param event Type the event type to set this event object to.
		 * 
		 */
		public function SwagLoaderEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//SwagLoaderEvent class
	
}//package