/*
 * License
 */
package org.igniterealtime.xiff.bookmark
{
	
	import flash.xml.XMLNode;
	
	import org.igniterealtime.xiff.data.ISerializable;

	public class UrlBookmark implements ISerializable
	{
		private var node:XMLNode;
		
		/**
		 * 
		 * @param	name
		 * @param	url
		 */
		public function UrlBookmark(name:String = null, url:String = null)
		{
			if (!name && !url)
			{
				return;
			}
			else if (!name || !url) 
			{
				throw new Error("Name and url cannot be null, they must either both be null or an Object");
			}
			
			node = new XMLNode(1, "url");
			node.attributes.name = name;
			node.attributes.url = url;
		}
		
		public function get name():String 
		{
			return node.attributes.name;
		}
		
		public function get url():String 
		{
			return node.attributes.uri;
		}
		
		public function serialize(parentNode:XMLNode):Boolean 
		{
			parentNode.appendChild(node.cloneNode(true));
			return true;
		}
		
		public function deserialize(node:XMLNode):Boolean 
		{
			this.node = node.cloneNode(true);
			return true;
		}
		
	}
}