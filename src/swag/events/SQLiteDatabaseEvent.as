package swag.events {
	
	/**
	 * Used by the <code>SQLiteDatabase</code> class to broadcast updates and statuses.
	 *  
	 * @author Patrick Bay
	 * 
	 */
	import flash.data.SQLResult;
	public class SQLiteDatabaseEvent extends SwagEvent {
		
		/**
		 * Dispatched when a database query responds with a result. 
		 */
		public static const ONRESULT:String="SwagEvent.SQLiteDatabaseEvent.ONRESULT";		
		
		/**
		 * Contains the result of the query for which the event was broadcast, or <em>null</em> otherwise. 
		 */
		public var result:SQLResult=null;
		/**
		 * All the updated rows that the query affected (same as the <code>result.data</code> property), or <em>null</em> if no rows were affected.
		 */
		public var resultRows:Array=null;
		/**
		 * The number of rows in the returned <code>resultRows</code> array, or 0 if no rows are included. 
		 */
		public var numRows:uint=0;
		/**
		 * The number of rows that were changed or affected by the query. This number will only be greated than 0 if a query such as
		 * INSERT, UPDATE, or DELETE was used. 
		 */
		public var numRowsChanged:uint=0;
		
		public function SQLiteDatabaseEvent(eventType:String=null) {
			super(eventType);
		}//constructor
		
	}//SQLiteDatabaseEvent class
	
}//package