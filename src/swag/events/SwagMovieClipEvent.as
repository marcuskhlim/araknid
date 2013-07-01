package swag.events {
	
	import swag.interfaces.events.ISwagMovieClipEvent;
	
	public class SwagMovieClipEvent extends SwagEvent implements ISwagMovieClipEvent	{
		
		/**
		 * Dispatched when a playback operation of any kind is started on the associated movie clip.
		 */
		public static const START:String="SwagEvent.SwagMovieClipEvent.START";
		/**
		 * Dispatched when a playback operation of any kind is completed on the associated movie clip.
		 */
		public static const END:String="SwagEvent.SwagMovieClipEvent.END";
		/**
		 * Dispatched when a playback advances on the associated movie clip.
		 */
		public static const FRAME:String="SwagEvent.SwagMovieClipEvent.FRAME";
		
		
		public function SwagMovieClipEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//SwagMovieClipEvent class
	
}//package