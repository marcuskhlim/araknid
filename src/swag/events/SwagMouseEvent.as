package swag.events {
	
	import flash.display.InteractiveObject;
	
	import swag.events.SwagEvent;
	import swag.interfaces.events.ISwagMouseEvent;
	
	/**
	 * Used to dispatch mouse related events for the SwAG toolkit.
	 * <p>SwAG mouse events are similar, and often mimic, the functionality of the standard Flash MouseEvent, but
	 * also provide additional features and information.</p>
	 *  
	 * @author Patrick Bay
	 * 
	 */
	public class SwagMouseEvent extends SwagEvent implements ISwagMouseEvent	{		
		
		/**
		 * Mimics the functionality of the standard MouseEvent.CLICK event 
		 */
		public static const CLICK:String="SwagEvent.SwagMouseEvent.CLICK";
		/**
		 * Mimics the functionality of the standard MouseEvent.DOUBLE_CLICK event, also enabling and
		 * setting any required properties for the associated display object. 
		 */
		public static const DOUBLE_CLICK:String="SwagEvent.SwagMouseEvent.DOUBLE_CLICK";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_DOWN event. 
		 */
		public static const DOWN:String="SwagEvent.SwagMouseEvent.DOWN";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_UP event. 
		 */
		public static const UP:String="SwagEvent.SwagMouseEvent.UP";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_OVER event. 
		 */
		public static const OVER:String="SwagEvent.SwagMouseEvent.OVER";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_OUT event. 
		 */
		public static const OUT:String="SwagEvent.SwagMouseEvent.OUT";
		/**
		 * Mimics the functionality of the standard MouseEvent.ROLL_OVER event. 
		 */
		public static const ROLL_OVER:String="SwagEvent.SwagMouseEvent.ROLL_OVER";
		/**
		 * Mimics the functionality of the standard MouseEvent.ROLL_OUT event. 
		 */
		public static const ROLL_OUT:String="SwagEvent.SwagMouseEvent.ROLL_OUT";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_WHEEL event. 
		 */
		public static const WHEEL:String="SwagEvent.SwagMouseEvent.WHEEL";		
		
		/**
		 * Default constructor for the event class.
		 *  
		 * @param eventType The event type to create. Use one of the associated class constants to associate
		 * with the event instance.
		 * 
		 */
		public function SwagMouseEvent(eventType:String=null) {
			this.type=eventType;
		}//constructor	
		
	}//SwagMouseEvent class
	
}//package