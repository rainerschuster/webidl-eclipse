/*
 * generated by Xtext
 */
package com.rainerschuster.webidl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import com.rainerschuster.webidl.webIDL.Interface
import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import com.rainerschuster.webidl.webIDL.ExtendedInterfaceMember
import com.rainerschuster.webidl.webIDL.InterfaceMember
import com.rainerschuster.webidl.webIDL.Const
import com.rainerschuster.webidl.webIDL.ExtendedAttributeList
import com.rainerschuster.webidl.webIDL.Operation
import com.rainerschuster.webidl.webIDL.Argument
import com.rainerschuster.webidl.webIDL.Attribute
import com.rainerschuster.webidl.webIDL.Type
import com.rainerschuster.webidl.webIDL.UnionType
import com.rainerschuster.webidl.webIDL.DOMExceptionType
import com.rainerschuster.webidl.webIDL.DateType
import com.rainerschuster.webidl.webIDL.ByteStringType
import com.rainerschuster.webidl.webIDL.USVStringType
import com.rainerschuster.webidl.webIDL.ArrayBufferType
import com.rainerschuster.webidl.webIDL.DataViewType
import com.rainerschuster.webidl.webIDL.Int8ArrayType
import com.rainerschuster.webidl.webIDL.Int16ArrayType
import com.rainerschuster.webidl.webIDL.Int32ArrayType
import com.rainerschuster.webidl.webIDL.Uint8ArrayType
import com.rainerschuster.webidl.webIDL.Uint16ArrayType
import com.rainerschuster.webidl.webIDL.Uint32ArrayType
import com.rainerschuster.webidl.webIDL.Uint8ClampedArrayType
import com.rainerschuster.webidl.webIDL.Float32ArrayType
import com.rainerschuster.webidl.webIDL.Float64ArrayType
import com.rainerschuster.webidl.webIDL.PromiseType
import com.rainerschuster.webidl.webIDL.SequenceType
import com.rainerschuster.webidl.webIDL.BooleanType
import com.rainerschuster.webidl.webIDL.ByteType
import com.rainerschuster.webidl.webIDL.OctetType
import com.rainerschuster.webidl.webIDL.ShortType
import com.rainerschuster.webidl.webIDL.LongType
import com.rainerschuster.webidl.webIDL.LongLongType
import com.rainerschuster.webidl.webIDL.FloatType
import com.rainerschuster.webidl.webIDL.DoubleType
import com.rainerschuster.webidl.webIDL.DOMStringType
import com.rainerschuster.webidl.webIDL.ObjectType
import com.rainerschuster.webidl.webIDL.VoidType
import com.rainerschuster.webidl.webIDL.AnyType
import com.rainerschuster.webidl.webIDL.ReferenceType
import com.rainerschuster.webidl.webIDL.Definition
import com.rainerschuster.webidl.webIDL.CallbackRest
import com.rainerschuster.webidl.webIDL.Dictionary
import com.rainerschuster.webidl.webIDL.ReturnType
import com.rainerschuster.webidl.webIDL.Typedef
import com.rainerschuster.webidl.webIDL.Special
import com.rainerschuster.webidl.util.NameUtil

/**
 * Generates code from your model files on save.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#TutorialCodeGeneration
 */
class WebIDLGenerator implements IGenerator {

	@Inject extension IQualifiedNameProvider

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		// TODO Same for CallbackFunction!
		for (e : resource.allContents.toIterable.filter(typeof(Interface))) {
			fsa.generateFile(e.fullyQualifiedName.toString("/") + ".java", e.binding);
		};
		for (e : resource.allContents.toIterable.filter(typeof(CallbackRest))) {
			fsa.generateFile(e.fullyQualifiedName.toString("/") + ".java", e.binding);
		};
	}

	// TODO consider eCrossReferences for implementsStatements!

	def binding(Interface iface) '''
		«IF iface.eContainer.fullyQualifiedName != null»
			package «iface.eContainer.fullyQualifiedName»;

		«ENDIF»

		public interface «iface.name»«IF iface.inherits != null» extends «iface.inherits.fullyQualifiedName»«ENDIF» {
		«FOR i : iface.interfaceMembers SEPARATOR '\n'»
			«binding(i)»
		«ENDFOR»
		}
	'''

	def binding(CallbackRest callback) '''
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
		«constant.type.toJavaType» «NameUtil.getEscapedJavaName(constant.name)» = «constant.constValue»;

	'''

	// TODO is... for boolean! (non-nullable?!)
	def dispatch bindingInterfaceMember(ExtendedAttributeList eal, Attribute attribute) '''
		«IF !attribute.inherit»
			«attribute.type.toJavaType» get«attribute.name.toFirstUpper»();
		«ENDIF»
		«IF !attribute.readOnly»
			void set«attribute.name.toFirstUpper»(«attribute.type.toJavaType» «NameUtil.getEscapedJavaName(attribute.name)»);
		«ENDIF»

	'''

	// FIXME What if more than one specials occur, e.g.: setter creator void (unsigned long index, HTMLOptionElement? option);
	def dispatch bindingInterfaceMember(ExtendedAttributeList eal, Operation operation) '''
		«operation.type.toJavaType» «IF operation.name.nullOrEmpty»«IF operation.specials.contains(Special.GETTER)»_get«ELSEIF operation.specials.contains(Special.SETTER)»_set«ELSEIF operation.specials.contains(Special.CREATOR)»_create«ELSEIF operation.specials.contains(Special.DELETER)»_delete«ELSEIF operation.specials.contains(Special.LEGACYCALLER)»_call«ENDIF»«ELSE»«NameUtil.getEscapedJavaName(operation.name)»«ENDIF»(«FOR i : operation.arguments SEPARATOR ', '»«binding(i)»«ENDFOR»);
	'''

	def binding(Argument parameter) '''
		«parameter.type.toJavaType»«IF parameter.ellipsis»...«ENDIF» «NameUtil.getEscapedJavaName(parameter.name)»'''




















	def static String toJavaType(ReturnType type) {
		switch (type) {
			VoidType: "void"
			Type: type.toJavaType
		}
	}

	def static String toJavaType(Type type) {
		switch type {
			ReferenceType : {
//				logger.debug("ReferenceType");
				var Definition resolved = type.typeRef;
				if (resolved != null) {
					switch (resolved) {
						Interface : {/*logger.debug("InterfaceType");*/ return resolved.name}
						Dictionary : {/*logger.debug("DictionaryType"); */return "java.util.HashMap<java.lang.String,java.lang.Object>"}
						com.rainerschuster.webidl.webIDL.Enum : return "java.lang.String"
						// TODO implement CallbackFunctionType!
						CallbackRest : {/*logger.debug("CallbackFunctionType");*/ return resolved.name}
						Typedef : {/*logger.debug("Typedef");*/ return resolved.type.toJavaType}
					}
				} else {
					return null
				}
			} // type.name
			AnyType: return "java.lang.Object"
			VoidType : return "void"
			BooleanType : return "boolean"
			ByteType : return "byte"
			OctetType : return "byte"
			ShortType : return "short"
//			UnsignedShortType : return "short"
			LongType : return "int"
//			UnsignedLongType : return "int"
			LongLongType : return "long"
//			UnsignedLongLongType : return "long"
			FloatType : return "float"
//			UnrestrictedFloatType : return "float"
			DoubleType : return "double"
//			UnrestrictedDoubleType : return "double"
			DOMStringType : return "java.lang.String"
			ObjectType : return "java.lang.Object"
			// TODO implement InterfaceType!
			// TODO Corresponding Java escaped identifier
//			InterfaceSymbol : {/*logger.debug("InterfaceType");*/ return type.name}
//			DictionarySymbol : {/*logger.debug("DictionaryType"); */return "java.util.HashMap<java.lang.String,java.lang.Object>"}
//			EnumerationSymbol : return "java.lang.String"
//			// TODO implement CallbackFunctionType!
//			CallbackFunctionSymbol : {/*logger.debug("CallbackFunctionType");*/ return type.name}
//			NullableType : {
//				val Type subType = type.innerType;
//				switch(subType) {
//					BooleanType : return "java.lang.Boolean"
//					ByteType : return "java.lang.Byte"
//					OctetType : return "java.lang.Byte"
//					ShortType : return "java.lang.Short"
////					UnsignedShortType : return "java.lang.Short"
//					LongType : return "java.lang.Integer"
////					UnsignedLongType : return "java.lang.Integer"
//					LongLongType : return "java.lang.Long"
////					UnsignedLongLongType : return "java.lang.Long"
//					FloatType : return "java.lang.Float"
////					UnrestrictedFloatType : return "java.lang.Float"
//					DoubleType : return "java.lang.Double"
////					UnrestrictedDoubleType : return "java.lang.Double"
//					DOMStringType : return "java.lang.String"
//					ByteStringType : return "String" // FIXME This is not defined!
//					USVStringType : return "String" // FIXME This is not defined!
//					default : {
//						val String subTypeString = toJavaType(subType);
//						if (subTypeString != null) {
//							return subTypeString;
//						}
//						return null;
//					}
//				}
//			}
			SequenceType : {
//				logger.debug("SequenceType");
				val Type subType = type.type;
				val String subTypeString = toJavaType(subType);
				if (subTypeString != null) {
					return subTypeString + "[]";
				}
				return null;
			}
//			ArrayType : {
////				logger.debug("ArrayType");
//				val Type subType = toType(type.elementType);
////				val Type subType = type.elementType;
//				if (subType instanceof PrimitiveType) {
//					return "org.w3c.dom." + subType.getName() + "Array";
//				}
//				val String subTypeString = toJavaType(subType);
//				if (subTypeString != null) {
//					return "org.w3c.dom.ObjectArray<" + subTypeString + ">";
//				}
//				return null;
//			}
			PromiseType : {
//				logger.debug("PromiseType");
//				val Type subType = type.elementType;
//				val String subTypeString = toJavaType(subType, resolver);
				return "java.lang.Object"
			}
			UnionType : {/*logger.debug("UnionType");*/ return "java.lang.Object"}
			DOMExceptionType : {/*logger.debug("DOMExceptionType");*/ return "java.lang.Object"}
			DateType : return "java.util.Date"
			ByteStringType : return "String"
			USVStringType : return "String"
			ArrayBufferType : return "ArrayBuffer"
			DataViewType : return "DataView"
			Int8ArrayType : return "Int8Array"
			Int16ArrayType : return "Int16Array"
			Int32ArrayType : return "Int32Array"
			Uint8ArrayType : return "Uint8Array"
			Uint16ArrayType : return "Uint16Array"
			Uint32ArrayType : return "Uint32Array"
			Uint8ClampedArrayType : return "Uint8ClampedArray"
			Float32ArrayType : return "Float32Array"
			Float64ArrayType : return "Float64Array"
//			ArrayBufferType : return "java.lang.Object"
//			DataViewType : return "java.lang.Object"
//			Int8ArrayType : return "java.lang.Object"
//			Int16ArrayType : return "java.lang.Object"
//			Int32ArrayType : return "java.lang.Object"
//			Uint8ArrayType : return "java.lang.Object"
//			Uint16ArrayType : return "java.lang.Object"
//			Uint32ArrayType : return "java.lang.Object"
//			Uint8ClampedArrayType : return "java.lang.Object"
//			Float32ArrayType : return "java.lang.Object"
//			Float64ArrayType : return "java.lang.Object"
			default : {/*logger.warn("Unknown type {}!", type);*/ return null}
		}
	}


}
