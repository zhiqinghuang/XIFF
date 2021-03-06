/*
 * Copyright (C) 2003-2012 Igniterealtime Community Contributors
 *
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
 *     Mark Walters <mark@yourpalmark.com>
 *     Michael McCarthy <mikeycmccarthy@gmail.com>
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.igniterealtime.xiff.data
{
	import org.flexunit.asserts.assertEquals;
	
	public class PresenceTest
	{
		
		[Test( description="Presence show away" )]
		public function testShowAway():void
		{
			var show:String = "away";
			var presence:Presence = new Presence();
			presence.show = show;
			
			assertEquals( show, presence.show );
		}
		
		[Test( description="Presence show chat" )]
		public function testShowChat():void
		{
			var show:String = "chat";
			var presence:Presence = new Presence();
			presence.show = show;
			
			assertEquals( show, presence.show );
		}
		
		[Test( description="Presence show dnd" )]
		public function testShowDnd():void
		{
			var show:String = "dnd";
			var presence:Presence = new Presence();
			presence.show = show;
			
			assertEquals( show, presence.show );
		}
		
		[Test( description="Presence show xa" )]
		public function testShowXa():void
		{
			var show:String = "xa";
			var presence:Presence = new Presence();
			presence.show = show;
			
			assertEquals( show, presence.show );
		}
		
		[Test( description="Presence status" )]
		public function testStatus():void
		{
			var status:String = "I am somewhere..";
			var presence:Presence = new Presence();
			presence.status = status;
			
			assertEquals( status, presence.status );
		}
		
		[Test( description="Presence priority" )]
		public function testPriority():void
		{
			var priority:int = 5;
			var presence:Presence = new Presence();
			presence.priority = priority;
			
			assertEquals( priority, presence.priority );
		}
		
		[Test( description="Presence parse from XML - show dnd" )]
		public function testParseShowDnd():void
		{
			var incoming:XML = <presence>
				 <show>dnd</show>
			   </presence>;
			var testValue:String = "dnd";
			
			var presence:Presence = new Presence();
			presence.xml = incoming;
			
			assertEquals( testValue, presence.show );
		}
		
		
		[Test( description="Presence parse from XML - type error" )]
		public function testParseTypeError():void
		{
			var incoming:XML = <presence
				from='coven@chat.shakespeare.lit/thirdwitch'
				id='273hs51g'
				to='hag66@shakespeare.lit/pda'
				type='error'>
			  <error by='coven@chat.shakespeare.lit' type='modify'>
				<jid-malformed xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
			  </error>
			</presence>;
			var testValue:String = "error";
			
			var presence:Presence = new Presence();
			presence.xml = incoming;
			
			assertEquals( testValue, presence.type );
		}
		
		
		
		
		/**
		 * @see http://xmpp.org/extensions/xep-0203.html
		 */
		[Test( description="Presence parse from XML - time" )]
		public function testParseTime():void
		{
			var incoming:XML = <presence from='juliet@capulet.com/balcony' to='romeo@montague.net'>
			  <status>anon!</status>
			  <show>xa</show>
			  <priority>1</priority>
			  <delay xmlns='urn:xmpp:delay'
				 from='juliet@capulet.com/balcony'
				 stamp='2002-09-10T23:08:25Z'/>
			</presence>;
			var testValue:String = "Tue Sep 10 23:08:25 2002 UTC";
			
			var presence:Presence = new Presence();
			presence.xml = incoming;
			
			assertEquals( testValue, presence.time.toUTCString() );
		}
		
		/**
		 * @see http://xmpp.org/extensions/xep-0091.html
		 */
		[Test( description="Presence parse from XML - time (legacy version)" )]
		public function testParseTimeLegacy():void
		{
			var incoming:XML = <presence from='juliet@capulet.com/balcony' to='romeo@montague.net'>
			  <status>anon!</status>
			  <show>xa</show>
			  <priority>1</priority>
			  <x xmlns='jabber:x:delay'
				 from='juliet@capulet.com/balcony'
				 stamp='20020910T23:08:25'/>
			</presence>;
			var testValue:String = "Tue Sep 10 23:08:25 2002 UTC";

			var presence:Presence = new Presence();
			presence.xml = incoming;
			
			assertEquals( testValue, presence.time.toUTCString() );
		}
		


	}
}
