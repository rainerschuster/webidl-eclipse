/*
 * generated by Xtext
 */
package com.rainerschuster.webidl.validation

import com.rainerschuster.webidl.webIDL.Argument
import com.rainerschuster.webidl.webIDL.Const
import com.rainerschuster.webidl.webIDL.Interface
import com.rainerschuster.webidl.webIDL.Iterable_
import com.rainerschuster.webidl.webIDL.Operation
import com.rainerschuster.webidl.webIDL.PromiseType
import com.rainerschuster.webidl.webIDL.Special
import com.rainerschuster.webidl.webIDL.WebIDLPackage
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.validation.Check
import com.rainerschuster.webidl.webIDL.ExtendedAttribute
import com.rainerschuster.webidl.webIDL.PartialInterface
import com.rainerschuster.webidl.webIDL.ExtendedDefinition

import static extension com.rainerschuster.webidl.util.ExtendedAttributeUtil.*

/**
 * Custom validation rules. 
 *
 * see http://www.eclipse.org/Xtext/documentation.html#validation
 */
class WebIDLValidator extends AbstractWebIDLValidator {

//  public static val INVALID_NAME = 'invalidName'
//
//	@Check
//	def checkGreetingStartsWithCapital(Greeting greeting) {
//		if (!Character.isUpperCase(greeting.name.charAt(0))) {
//			warning('Name should start with a capital', 
//					MyDslPackage.Literals.GREETING__NAME,
//					INVALID_NAME)
//		}
//	}

	// See 3.2. Interfaces
	@Check
	def checkExtendedAttributeOnPartialInterface(PartialInterface partialInterface) {
		val forbiddenExtendedAttributes = #[EA_ARRAY_CLASS, EA_CONSTRUCTOR, EA_IMPLICIT_THIS, EA_NAMED_CONSTRUCTOR, EA_NO_INTERFACE_OBJECT];
		val containerDefinition = partialInterface.eContainer as ExtendedDefinition;
		val extendedAttributes = containerDefinition.eal.extendedAttributes;
		for (String extendedAttribute : forbiddenExtendedAttributes) {
			if (extendedAttributes.containsExtendedAttribute(extendedAttribute)) {
				extendedAttributes.getAllExtendedAttributes(extendedAttribute).forEach[
					warning('The extended attribute "' + it.nameRef + '" must not be specified on partial interface definitions', 
							it,
							WebIDLPackage.Literals.EXTENDED_ATTRIBUTE__NAME_REF)
				];
			}
		}
	}

	// See 3.2.1. Constants

	@Check
	def checkConstantName(Const constant) {
		if ("prototype".equals(constant.name)) {
			error('The identifier of a constant must not be “prototype”', 
					constant,
					WebIDLPackage.Literals.CONST__NAME)
		}
	}

	// See 3.2.2. Attributes

//	@Check
//	def checkAttributeName(Attribute attribute) {
//		if (attribute.static && "prototype".equals(attribute.name)) {
//			error('The identifier of a static attribute must not be “prototype”', 
//					attribute,
//					WebIDLPackage.Literals.ATTRIBUTE_NAME)
//		}
//	}

	// See 3.2.3. Operations

	@Check
	def checkSpecialOperationNameNotEmpty(Operation operation) {
		if (operation.name.nullOrEmpty && operation.specials.empty) {
			error('If an operation has no identifier, then it must be declared to be a special operation using one of the special keywords', 
					operation,
					WebIDLPackage.Literals.OPERATION__NAME)
		}
	}

//	@Check
//	def checkOperationName(Operation operation) {
//		if (operation.static && "prototype".equals(operation.name)) {
//			error('The identifier of a static operation must not be “prototype”', 
//					operation,
//					WebIDLPackage.Literals.OPERATION__NAME)
//		}
//	}

	def checkArgumentEllipsisFinal(List<Argument> arguments, EObject source, EStructuralFeature feature) {
		arguments.filter[it.ellipsis].forEach[
			if (it != arguments.last) {
				error('An argument must not be declared with the ... token unless it is the final argument in the operation’s argument list', 
						source,
						feature)
			}
		]
	}

//	@Check
//	def checkArgumentEllipsisFinal(CallbackRest callback) {
//		checkArgumentEllipsisFinal(callback.arguments, callback, WebIDLPackage.Literals.CALLBACK__ARGUMENTS)
//	}

	@Check
	def checkArgumentEllipsisFinal(Operation operation) {
		// TODO This marks the first argument (although this one is not the problem)!
		checkArgumentEllipsisFinal(operation.arguments, operation, WebIDLPackage.Literals.OPERATION__ARGUMENTS)
	}

	@Check
	def checkSpecialKeywordOnce(Operation operation) {
		for (Special special : operation.specials) {
			if (operation.specials.filter[it == special].length >= 2) {
				// TODO This marks the first special (although this one is not the problem)!
				error('A given special keyword must not appear twice on an operation', 
						operation,
						WebIDLPackage.Literals.OPERATION__SPECIALS)
			}
		}
	}

	// See 3.2.4.1. Legacy callers

	@Check
	def checkLegacyCallersDoNotReturnPromiseType(Operation operation) {
		if (operation.specials.contains(Special.LEGACYCALLER) && operation.type instanceof PromiseType) {
			error('Legacy callers must not be defined to return a promise type', 
					operation,
					WebIDLPackage.Literals.OPERATION__TYPE)
		}
	}

	// See 3.2.4.2. Stringifiers

//	@Check
//	def checkStringifierAttributeNotString(Attribute attribute) {
//		if (attribute.specials.contains(Special.STRINGIFIER) && attribute.type instanceof DOMStringType) {
//			error('The stringifier keyword must not be placed on an attribute unless it is declared to be of type DOMString', 
//					attribute,
//					WebIDLPackage.Literals.ATTRIBUTE__TYPE)
//		}
//	}
//
//	@Check
//	def checkStringifierAttributeNotStatic(Attribute attribute) {
//		if (attribute.specials.contains(Special.STRINGIFIER) && attribute.static) {
//			error('The stringifier keyword must not be placed on a static attribute', 
//					attribute,
//					WebIDLPackage.Literals.ATTRIBUTE__STATIC)
//		}
//	}

	// See 3.2.7. Iterable declarations

//	@Check
//	def checkIterableInterfaceMembers(Interface iface) {
//		if (iface.interfaceMembers.exists[it.interfaceMember instanceof Iterable_]) {
//			iface.interfaceMembers.filter["entries".equals(it.name) || "keys".equals(it.name) || "values".equals(it.name)].forEach[
//				error('Interfaces with iterable declarations must not have any interface members named “entries”, “keys” or “values”', 
//						iface,
//						WebIDLPackage.Literals.INTERFACE__INTERFACE_MEMBERS)
//			]
//		}
//	}

	@Check
	def checkIterableNotMoreThanOnce(Interface iface) {
		// TODO This marks the first interface member (although this one is not the problem)!
		if (iface.interfaceMembers.filter[it.interfaceMember instanceof Iterable_].length >= 2) {
			error('An interface must not have more than one iterable declaration', 
					iface,
					WebIDLPackage.Literals.INTERFACE__INTERFACE_MEMBERS)
		}
	}

	@Check
	def checkDeprecatedExtendedAttribute(ExtendedAttribute extendedAttribute) {
		if (EA_TREAT_NON_CALLABLE_AS_NULL.equals(extendedAttribute.nameRef)) {
			warning('The extended attribute TreatNonCallableAsNull was renamed to TreatNonObjectAsNull', 
					extendedAttribute,
					WebIDLPackage.Literals.EXTENDED_ATTRIBUTE__NAME_REF)
		}
	}

	@Check
	def checkUnknownExtendedAttribute(ExtendedAttribute extendedAttribute) {
		if (!KNOWN_EXTENDED_ATTRIBUTES.contains(extendedAttribute.nameRef)) {
			warning('The extended attribute "' + extendedAttribute.nameRef + '" is no known extended attribute', 
					extendedAttribute,
					WebIDLPackage.Literals.EXTENDED_ATTRIBUTE__NAME_REF)
		}
	}

}
