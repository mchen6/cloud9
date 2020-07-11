/*
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 *
 */
// #ifdef __AMLFLASHPLAYER || __INC_ALL

/**
 * Element displaying the contents of a .swf (adobe flash) file.
 *
 * @constructor
 * @define flashplayer
 * @allowchild {smartbinding}
 *
 *
 * @inherits apf.BaseSimple
 *
 * @author      Ruben Daniels (ruben AT ajax DOT org)
 * @version     %I%, %G%
 * @since       0.9
 *
 * @binding value  Determines the way the value for the element is retrieved 
 * from the bound data.
 * Example:
 * Sets the flash source text based on data loaded into this component.
 * <code>
 *  <a:flashplayer value="[@src]">
 *      <a:model>
 *          <data src="flash.swf" />
 *      </a:model>
 *  </a:flashplayer>
 * </code>
 */
apf.flashplayer = function(struct, tagName){
    this.$init(tagName || "flashplayer", apf.NODE_VISIBLE, struct);
};

(function(){
    this.implement(
        //#ifdef __WITH_DATAACTION
        apf.DataAction,
        //#endif
        apf.StandardBinding
    );
    
    // *** Public methods *** //
    
    //#ifdef __WITH_CONVENIENCE_API
    
    /**
     * @ref global#setValue
     */
    this.setSrc = function(value){
        this.setProperty("src", value, false, true);
    };
    
    //#endif
    
    // *** Properties and attributes *** //
    
    this.$supportedProperties.push("value", "allowfullscreen", "flashvars");
    this.$propHandlers["src"] = function(value){
        //this.$ext.getElementsByTagName("param")[2].setAttribute("value", value);
        this.$ext.getElementsByTagName("object")[0].setAttribute("data", value);
//        this.$ext.getElementsByTagName("embed")[0].setAttribute("src", value);
    };
    this.$propHandlers["allowfullscreen"] = function(value){
        this.$ext.getElementsByTagName("param")[1].setAttribute("value", value);
//        this.$ext.getElementsByTagName("embed")[0].setAttribute("allowFullScreen", value);
    }
    this.$propHandlers["flashvars"] = function(value){
        this.$ext.getElementsByTagName("param")[3].setAttribute("value", value);
//        this.$ext.getElementsByTagName("embed")[0].setAttribute("flashvars", value);
    }
    this.$propHandlers["bgcolor"] = function(value){
        this.$ext.getElementsByTagName("param")[4].setAttribute("value", value);
//        this.$ext.getElementsByTagName("embed")[0].setAttribute("bgcolor", value);
    }
    this.$propHandlers["wmode"] = function(value){
        this.$ext.getElementsByTagName("param")[5].setAttribute("value", value);
//        this.$ext.getElementsByTagName("embed")[0].setAttribute("wmode", value);
    }
    
    // *** Init *** //
    
    this.$draw = function(){
        //Build Main Skin
        this.$ext = this.$pHtmlNode.appendChild(document.createElement("div"));
        if (this.getAttribute("style"))
            this.$ext.setAttribute("style", this.getAttribute("style"));
        this.$ext.onclick = function(){this.host.dispatchEvent("click");}
        
        var src = this.getAttribute("src") || "";
        this.$ext.insertAdjacentHTML("beforeend",
            '<object \
              width="100%" \
              height="100%" \
              data="' + src + '" \
              type="application/x-shockwave-flash">\
                <param name="allowfullscreen" value="true">\
                <param name="allowscriptaccess" value="always">\
                <param name="quality" value="high">\
                <param name="flashvars" value="">\
                <param name="bgcolor" value="#000000">\
                <param name="cachebusting" value="false">\
            </object>')
            /*                <param name="allowScriptAccess" value="always" />\
                <param name="allowFullScreen" value="false" />\
                <param name="movie" value="' + src + '" />\
                <param name="FlashVars" value="false" />\
                <param name="bgcolor" value="#ffffff" />\
                <param name="wmode" value="high" />\
                <param name="play" value="true" />\
                <param name="menu" value="false" />\
                <param name="quality" value="high" />\
'<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" \
              codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" \
              width="100%" \
              height="100%" \
              data="' + src + '" \
              type="application/x-shockwave-flash" \
              align="middle">\
              <embed src="' + src + '" play="true" menu="false" \
                  quality="high" bgcolor="#ffffff" width="100%" \
                  height="100%" align="middle" allowScriptAccess="always" \
                  allowFullScreen="false" type="application/x-shockwave-flash" \
                  pluginspage="http://www.macromedia.com/go/getflashplayer" />\*/
    };
    
    this.$loadAml = function(x){
    };
}).call(apf.flashplayer.prototype = new apf.GuiElement());

apf.aml.setElement("flashplayer", apf.flashplayer);
// #endif
