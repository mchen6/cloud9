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

// #ifdef __AMLCONTEXTMENU || __INC_ALL

/**
 * This element specifies which menu is shown when a
 * contextmenu is requested by a user for a AML node.
 * 
 * #### Example
 *
 * This example shows a list that shows the mnuRoot menu when the user
 * right clicks on the root {@link term.datanode data node}. Otherwise the `mnuItem` menu is
 * shown.
 *
 * ```xml, demo
 *  <a:application xmlns:a="http://ajax.org/2005/aml">
 *   <!-- startcontent -->
 *   <a:menu id="ctxMenu">
 *       <a:item>Choice 1!</a:item>
 *       <a:item>Choice 2!</a:item>
 *   </a:menu>
 *   <a:list width="300" id="list1">
 *       <a:contextmenu menu="ctxMenu" />
 *       <a:item>The Netherlands</a:item>
 *       <a:item>United States of America</a:item>
 *       <a:item>Poland</a:item>
 *   </a:list>
 *   <!-- endcontent -->
 *   Right-click on the list to reveal the context menu!
 *  </a:application>
 * ```
 *
 * @class apf.contextmenu
 * @define contextmenu
 * @inherits apf.AmlElement
 * @selection
 * @author      Ruben Daniels (ruben AT ajax DOT org)
 * @version     %I%, %G%
 * @since       0.4
 */
/**
 * @attribute {String} menu  Sets or gets the id of the menu element.
 */
/**
 * @attribute {String} select Sets or gets the XPath executed on the selected element of the databound element which determines whether this context menu is shown.
 *
 * 
 */
apf.contextmenu = function(){
    this.$init("contextmenu", apf.NODE_HIDDEN);
};

(function(){
    this.$amlNodes = [];
    
    //1 = force no bind rule, 2 = force bind rule
    this.$attrExcludePropBind = apf.extend({
        "match" : 1
    }, this.$attrExcludePropBind);
    
    this.register = function(amlParent){
        if (!amlParent.contextmenus)
            amlParent.contextmenus = [];
        amlParent.contextmenus.push(this);
    };
    
    this.unregister = function(amlParent){
        amlParent.contextmenus.remove(this);
    };
    
    this.addEventListener("DOMNodeInsertedIntoDocument", function(e){
        this.register(this.parentNode);
    });
}).call(apf.contextmenu.prototype = new apf.AmlElement());

apf.aml.setElement("contextmenu", apf.contextmenu);

// #endif
