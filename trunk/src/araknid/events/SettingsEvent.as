package araknid.events {
	
	import swag.events.SwagEvent;
	
	public class SettingsEvent extends SwagEvent {
		
		/**
		 * Dispatched (usually from the Settings class) when application settings are fully loaded and parsed.  
		 */
		public static const ONSETTINGSLOADED:String="SwagEvent.SettingsEvent.ONSETTINGSLOADED";		
		
		public function SettingsEvent(eventType:String=null){
			super(eventType);
		}//constructor
		
	}//SettingsEvent class
	
}//package