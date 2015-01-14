/*
 * Copyright 2015 Rainer Schuster
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
/*
 * generated by Xtext
 */
package com.rainerschuster.webidl.generator

import com.google.common.collect.ArrayListMultimap
import com.google.common.collect.ListMultimap
import com.google.inject.Inject
import com.rainerschuster.webidl.webIDL.Argument
import com.rainerschuster.webidl.webIDL.Attribute
import com.rainerschuster.webidl.webIDL.CallbackFunction
import com.rainerschuster.webidl.webIDL.Const
import com.rainerschuster.webidl.webIDL.Dictionary
import com.rainerschuster.webidl.webIDL.ExtendedAttributeList
import com.rainerschuster.webidl.webIDL.ExtendedInterfaceMember
import com.rainerschuster.webidl.webIDL.ImplementsStatement
import com.rainerschuster.webidl.webIDL.Interface
import com.rainerschuster.webidl.webIDL.InterfaceMember
import com.rainerschuster.webidl.webIDL.Operation
import com.rainerschuster.webidl.webIDL.PartialDictionary
import com.rainerschuster.webidl.webIDL.PartialInterface
import com.rainerschuster.webidl.webIDL.Special
import com.rainerschuster.webidl.webIDL.impl.InterfaceImpl
import java.util.List
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.naming.IQualifiedNameProvider

import static extension com.rainerschuster.webidl.util.NameUtil.*
import static extension com.rainerschuster.webidl.util.TypeUtil.*

/**
 * Generates code from your model files on save.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#TutorialCodeGeneration
 */
class WebIDLGenerator implements IGenerator {

	@Inject extension IQualifiedNameProvider

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		// Prepare helper structures
		var ListMultimap<Interface, Interface> implementsMap = ArrayListMultimap.create();
		var ListMultimap<Interface, PartialInterface> partialInterfaceMap = ArrayListMultimap.create();
		var ListMultimap<Dictionary, PartialDictionary> partialDictionaryMap = ArrayListMultimap.create();
		for (e : resource.allContents.toIterable.filter(typeof(ImplementsStatement))) {
			val ifaceB = e.ifaceB.resolveDefinition as Interface;
			implementsMap.put(e.ifaceA, ifaceB);
		};
		for (e : resource.allContents.toIterable.filter(typeof(PartialInterface))) {
			partialInterfaceMap.put(e.interfaceName, e);
		};
		for (e : resource.allContents.toIterable.filter(typeof(PartialDictionary))) {
			partialDictionaryMap.put(e.dictionaryName, e);
		};
		// Process Interfaces
		for (e : resource.allContents.toIterable.filter(typeof(Interface))) {
			val allImplements = newArrayList();
			if (e.inherits != null) {
				val inherits = e.inherits.resolveDefinition as Interface;
				allImplements.add(inherits);
			}
			if (implementsMap.containsKey(e)) {
				allImplements.addAll(implementsMap.get(e));
			}
//			val clone = EcoreUtil.copy(e);
			val myInterface = EcoreUtil.create(e.eClass()) as InterfaceImpl;
			myInterface.callback = e.callback;
			myInterface.name = e.name;
			myInterface.inherits = e.inherits;
			myInterface.getInterfaceMembers(); // Call to create list
			// TODO Overloaded operations / constructors
			e.interfaceMembers.forEach[
				myInterface.interfaceMembers.add(it);
			];
			if (partialInterfaceMap.containsKey(e)) {
				for (pi : partialInterfaceMap.get(e)) {
					pi.interfaceMembers.forEach[
						myInterface.interfaceMembers.add(it);
					];
				}
				// TODO Interfaces with [NoInterfaceObject]?
			}
			fsa.generateFile(e.fullyQualifiedName.toString("/") + ".java", e.binding(allImplements));
		};
		// Process Callback Functions
		// TODO Overloaded Callback Functions
		for (e : resource.allContents.toIterable.filter(typeof(CallbackFunction))) {
			fsa.generateFile(e.fullyQualifiedName.toString("/") + ".java", e.binding);
		};
	}

	def binding(Interface iface, List<Interface> allImplements) '''
		«IF iface.eContainer.fullyQualifiedName != null»
			package «iface.eContainer.fullyQualifiedName»;

		«ENDIF»

		public interface «iface.name»«IF !allImplements.nullOrEmpty» extends «FOR i : allImplements SEPARATOR ', '»«i.fullyQualifiedName»«ENDFOR»«ENDIF» {
		«FOR i : iface.interfaceMembers SEPARATOR '\n'»
			«binding(i)»
		«ENDFOR»
		}
	'''

	def binding(CallbackFunction callback) '''
		«IF callback.eContainer.fullyQualifiedName != null»
			package «callback.eContainer.fullyQualifiedName»;

		«ENDIF»

		public interface «callback.name» {
			«callback.type.toJavaType» call(«FOR i : callback.arguments SEPARATOR ', '»«binding(i)»«ENDFOR»);
		}
	'''

	def binding(ExtendedInterfaceMember member) {
		bindingInterfaceMember(member.eal, member.interfaceMember)
	}

	def dispatch bindingInterfaceMember(ExtendedAttributeList eal, InterfaceMember interfaceMember) {
		System.out.println("Fallback method - Unsupported type " + interfaceMember.class.name + "!");
	}

	/* TODO NON-SPEC: Added "public static final " */
	def dispatch bindingInterfaceMember(ExtendedAttributeList eal, Const constant) '''
		«constant.type.toJavaType» «constant.name.getEscapedJavaName» = «constant.constValue»;

	'''

	// TODO is... for boolean! (non-nullable?!)
	def dispatch bindingInterfaceMember(ExtendedAttributeList eal, Attribute attribute) '''
		«IF !attribute.inherit»
			«attribute.type.toJavaType» get«attribute.name.toFirstUpper»();
		«ENDIF»
		«IF !attribute.readOnly»
			void set«attribute.name.toFirstUpper»(«attribute.type.toJavaType» «attribute.name.getEscapedJavaName»);
		«ENDIF»

	'''

	// FIXME What if more than one specials occur, e.g.: setter creator void (unsigned long index, HTMLOptionElement? option);
	def dispatch bindingInterfaceMember(ExtendedAttributeList eal, Operation operation) '''
		«operation.type.toJavaType» «IF operation.name.nullOrEmpty»«IF operation.specials.contains(Special.GETTER)»_get«ELSEIF operation.specials.contains(Special.SETTER)»_set«ELSEIF operation.specials.contains(Special.CREATOR)»_create«ELSEIF operation.specials.contains(Special.DELETER)»_delete«ELSEIF operation.specials.contains(Special.LEGACYCALLER)»_call«ENDIF»«ELSE»«operation.name.getEscapedJavaName»«ENDIF»(«FOR i : operation.arguments SEPARATOR ', '»«binding(i)»«ENDFOR»);
	'''

	def binding(Argument parameter) '''
		«parameter.type.toJavaType»«IF parameter.ellipsis»...«ENDIF» «parameter.name.getEscapedJavaName»'''

}
