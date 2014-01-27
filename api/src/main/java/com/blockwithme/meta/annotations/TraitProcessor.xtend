/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.annotations

//import com.blockwithme.msgpack.Packer
//import com.blockwithme.msgpack.Unpacker
//import com.blockwithme.msgpack.templates.AbstractTemplate
//import com.blockwithme.msgpack.templates.ObjectType
//import com.blockwithme.msgpack.templates.PackerContext
//import com.blockwithme.msgpack.templates.TrackingType
//import com.blockwithme.msgpack.templates.UnpackerContext
import com.blockwithme.fn.util.Functor
import com.blockwithme.fn1.ProcObject
import com.blockwithme.traits.util.IndentationAwareStringBuilder
import java.io.Serializable
import java.lang.annotation.ElementType
import java.lang.annotation.Inherited
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
import java.util.HashSet
import java.util.LinkedHashSet
import java.util.Set
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static com.blockwithme.fn.util.Util.*

import static extension com.blockwithme.meta.annotations.ProcessorUtil.*
import static extension java.lang.Character.*
import static extension java.lang.Class.*
import static java.util.Objects.*
import com.google.inject.Provider
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend2.lib.StringConcatenationClient
import org.eclipse.xtend2.lib.StringConcatenationClient.TargetStringConcatenation

/**
 * Annotation for "traits"
 *
 * @author monster
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.CLASS)
@Inherited
@Active(MagicAnnotationProcessor)
annotation Trait {
	/** If the immutable it true all fields are final,
	 * and setter methods will return a new instance*/
	boolean immutable = false
	// TODO
	boolean concrete = true
	// Will only be added in sub-types, and only the return value will be
	// re-defined in sub-sub-types if concrete is true
//	def Instance copyFrom(ROInstance other)
}

/** Temp data structure used for Template generation. */
package class TemplateField {

	package String fieldName

	package String accessor

	package String mutator

	package String templateFieldName

	package TypeReference fieldType

	package MutableInterfaceDeclaration interf

}

package class FieldInfo {

	package MutableFieldDeclaration field

	package String name

	package TypeReference type

	package MutableInterfaceDeclaration interf

	package String error

	package boolean duplicate

	override toString() { name }
}

/**
 * The Actual Annotation processor for Trait Annotation. @Trait can be applied on interfaces only hence this class processes
 * MutableInterfaceDeclaration
 *
 * Register Global phase registers two new classes for each Trait interface XYATrait class and XYZTemplate class.
 * Transformation phase generates the implementation of these classes.
 */
class TraitProcessor extends InterfaceProcessor {
	/** The following type references are resolved at the setup time */
	var Type traitAnnotation
	var TypeReference builderType

	/** The trait can extend from any of the following interfaces,
	 * when found in the type hierarchy, these interfaces are ignored. */
	static Set<String> IGNORE_INTERFACES = #{
		Serializable.name, Cloneable.name, Provider.name,
		// TODO
		"com.blockwithme.meta.demo.input.BaseInstance"
	}

	/** Public constructor for this class. */
	new() {
		super(withAnnotation(Trait))
	}

	/** Returns true, if this type is an Interface that should be processed. */
	override boolean accept(TypeDeclaration td) {
		super.accept(td) && isValidTrait(td)
	}

	/** Called before processing a file. */
	override void init() {
		traitAnnotation = findTypeGlobally(Trait)
		builderType = newTypeReference(IndentationAwareStringBuilder)
	}

	/** Called after processing a file. */
	override void deinit() {
		traitAnnotation = null
		builderType = null
	}

	/** Utility method checks if a type is a Functor type. */
	def private isFunctor(TypeReference fieldType) {
		(getFunctor()).isAssignableFrom(fieldType)
	}

	/** Utility method checks if a type is a String type. */
	def private isString(TypeReference fieldType) {
		getString().isAssignableFrom(fieldType)
	}

	/** Checks if fieldType is of 'java.util.List' type. */
	def private isList(TypeReference fieldType) {
		if (fieldType.actualTypeArguments.size > 0) {
			getList().isAssignableFrom(fieldType.name.removeGeneric.newTypeReference)
		} else
			getList().isAssignableFrom(fieldType)
	}

	/** Each TypeDeclaration will be an interface, and it must be a @Trait, or "empty", inclusive their parents. */
	private def boolean isValidTraitOrMarker(TypeDeclaration _interface) {
		if (isMarker(_interface)) {
			return true
		}
		if (_interface.findAnnotation(traitAnnotation) != null) {
			for (parent : findParents(_interface)) {
				if (!isValidTraitOrMarker(parent)) {
					return false
				}
			}
			return true
		}
		false
	}

	/**
	 * A Validator method to check if interface okay to be a trait
	 * i.e. it should be annotated with @Trait and
	 * should not have any methods of its own.
	 */
	@SuppressWarnings("unused")
	private def boolean isValidTrait(TypeDeclaration _interface) {
		if (_interface.findAnnotation(traitAnnotation) != null) {
			for (parent : findParents(_interface)) {
				if (!isValidTraitOrMarker(parent)) {
					return false
				}
			}
			return true
		}
		false
	}

	/** Utility method to check if _interface is immutable depending on the 'immutable' parameter passed
	 * to its @Trait annotation */
	def boolean isImmutableTrait(MutableInterfaceDeclaration _interface){
		val ann = _interface.findAnnotation(traitAnnotation)
		var result = false
		if(ann != null){
			result = Boolean::valueOf(ann.getValue('immutable').toString)
		}
		result
	}

	/** Utility Method to find if class has a super class that is not an object */
	def private hasSuper(MutableClassDeclaration definingClazz) {
		definingClazz.extendedClass != null && definingClazz.extendedClass != getObject()
	}

	/** Utility method, Resolves and finds the Trait interface from Trait class name. */
	def private interfaceFromClassName(String className) {
		val index = className.lastIndexOf('Trait')
		val iName = className.substring(0, index)
		iName.findInterface
	}

	/** Utility method to recursively perform a function on all the fields of an interface
	 * and its super interfaces, skips 'Functor' fields. */
	def private void forAllFields(
		MutableInterfaceDeclaration interf,
		ProcObject<FieldInfo> func
	) {
		if (interf != null) {

			val sInterface = interf.sortedSuperInterfaces

			interf.declaredFields?.forEach [ f |
				//checking if the field is duplicate field
				val duplicate = newBooleanArrayOfSize(1)
				val error = newBooleanArrayOfSize(1)
				if (sInterface != null) {
					for (superI : sInterface) {
						superI.name.findInterface.forAllFields [
							if (f.simpleName == name) {
								if (f.type == type) {
									duplicate.set(0, true)
								} else {
									error.set(0, true)
								}
							}
						]
					}
				}
				if (!f.type.isFunctor) {
					val fieldInfo = new FieldInfo
					fieldInfo.field = f
					fieldInfo.name = f.simpleName
					fieldInfo.type = f.type
					fieldInfo.interf = interf
					if (duplicate.get(0)) {
						fieldInfo.duplicate = true
					} else if (error.get(0)) {
						fieldInfo.error = 'Duplicate field: ' + f.simpleName + ' with different types found in ' +
							interf.qualifiedName
					}
					func.apply(fieldInfo)
				}
			]
			if (sInterface != null) {
				for (superI : sInterface) {
					forAllFields(superI.name.findInterface, func)
				}
			}
		}
	}

	/** Utility method to check if class clz1 is Assignable from clz2 */
	def private checkType(Class<?> clz1, Class<?> clz2) {
		clz1.isAssignableFrom(clz2)
	}

	/** Utility method that removes generics type arguments from the class.qualifiedName */
	def private removeGeneric(String className) {
		val index = className.indexOf("<")
		if (index > 0)
			className.substring(0, index)
		else
			className
	}

	/** Utility method to remove '.' from fully qualified names and converting the next
	 * word to start with upper case */
	def private removeDots(String fullyQualifiedName) {

		var index = fullyQualifiedName.indexOf('.')
		var result = fullyQualifiedName
		while (index > 0) {
			result = result.substring(0, index) + result.substring(index + 1).toFirstUpper
			index = result.indexOf('.')
		}
		result
	}

	/** This method returns all fields that should be added to the trait implementation class
	 * which is generated from traitInterface. See {@link TraitProcessorUtil#generateTraitClassFields} */
	def private LinkedHashSet<FieldInfo> classFields(MutableInterfaceDeclaration traitInterface) {

		val result = new LinkedHashSet<FieldInfo>
		val superInterFields = new HashSet<FieldInfo>()
		traitInterface.superInterface?.forAllFields [
			superInterFields.add(it)
		]
		traitInterface.forAllFields [ fInfo |
			if (superInterFields == null || !superInterFields.contains(fInfo))
				result.add(fInfo)
		]
		result

	}

	/** Utility method to find the corresponding Trait Class for a Trait interface */
	def private findClass(MutableInterfaceDeclaration traitInterface) {
		findClass(traitInterface.qualifiedName + 'Trait')
	}

	/** Utility method returns all super interface of an Interface sorted by name */
	def private sortedSuperInterfaces(MutableInterfaceDeclaration interf) {
		interf.superInterfaces?.sort [ i1, i2 |
			i1.name.compareTo(i2.name)
		]
	}

	/** Utility method returns all super interface of an Interface */
	def private superInterfaces(MutableInterfaceDeclaration interf) {
		interf?.extendedInterfaces?.filter [
			!IGNORE_INTERFACES.contains(name)
		]
	}

	/** This method finds super trait interface for a given trait interface.
	 *  In case there is no super interface it returns null.
	 *  In case there are multiple trait super interfaces it returns the one
	 *  with maximum number of fields. The 'Functor' fields are ignored while
	 *  counting the number of fields in the interface. */
	def private superInterface(MutableInterfaceDeclaration interf) {

		var MutableInterfaceDeclaration result = null
		val superInterfaces = interf.sortedSuperInterfaces
		var superClassFields = 0
		if (!superInterfaces.nullOrEmpty) {
			for (superI : superInterfaces) {

				// count number of fields in this interface
				// and all its super interfaces
				val counter = newIntArrayOfSize(1)
				superI.name.findInterface.forAllFields [
					counter.set(0, counter.get(0) + 1)
				]
				if (counter.get(0) > superClassFields) {
					result = superI.name.findInterface
					superClassFields = counter.get(0)
				}
			}
		}
		result
	}

	/** Adds hashCode, toString and equals methods to a particular class. */
	def private addObjectMethods(MutableClassDeclaration clazz, MutableClassDeclaration superClass) {
		clazz.addHashCode(superClass)
		clazz.addToString(superClass)
		clazz.addEquals(superClass)
	}
//
//	/**
//	 * Add all arguments constructors to a particular Trait class.
//	 *
//	 *  @param clazz class to which the constructor is added.
//	 *  @param superTraits a list of super Trait interfaces if any
//	 * (excluding the heaviest interface from which the clazz will be inherited)  */
//	def private addAllArgConstructor(
//		MutableClassDeclaration clazz,
//		Iterable<? extends TypeReference> superTraits
//	) {
//
//		val superConstrArgs = new StringBuilder
//		val assignmentStr = new StringBuilder
//		val thisInterface = clazz.qualifiedName.interfaceFromClassName
//		val fields = thisInterface.classFields
//
//		clazz.addConstructor [ constrctr |
//			thisInterface.forAllFields [ fInfo |
//				val duplicate = newBooleanArrayOfSize(1)
//				if (fields.contains(fInfo)) {
//					fields.forEach [ classF |
//						if (classF == fInfo && classF.duplicate)
//							duplicate.set(0, true)
//					]
//					if (!duplicate.get(0))
//						assignmentStr.append('this.' + fInfo.name + ' = ' + fInfo.name + ';\n')
//				} else {
//					if (superConstrArgs.length > 0)
//						superConstrArgs.append(', ')
//					superConstrArgs.append(fInfo.name)
//				}
//				if (!duplicate.get(0))
//					constrctr.addParameter(fInfo.name, fInfo.type)
//			]
//			constrctr.docComment = 'The all Argument Constructor'
//			constrctr.body = [
//				'''
//					«IF superConstrArgs.length > 0»
//						super( «superConstrArgs.toString()» );
//					«ENDIF»
//					«assignmentStr.toString()»
//				''']
//		]
//	}

//	/**
//	 * Adds 'newXYZ' methods, where 'XYZ' is a string generated from fully qualified name of 'definingClazz', where
//	 * 'definingClazz' is either 'clazz' itself or any of its super classes. This method is added to 'clazz',
//	 * methods parameters are same as the all arg constructor of 'definingClazz'. one 'newXYZ' method is generated
//	 * for the current and one each for all its super Trait classes.
//	 *
//	 * <pre>
//	 * 	 Each method -
//	 *   	Takes arguments same as the constructor of the defining class.
//	 *   	Return a new instance of the *current* Trait class.
//	 * </pre> */
//	def private void addNewMethod(MutableClassDeclaration clazz, MutableClassDeclaration definingClazz) {
//
//		val MutableClassDeclaration superClass = if (definingClazz.hasSuper)
//				definingClazz.extendedClass.name.findClass
//		if (superClass != null) {
//			clazz.addNewMethod(superClass)
//		}
//		clazz.addMethod("new" + definingClazz.qualifiedName.removeDots.toFirstUpper) [ meth |
//			val argStr = new StringBuffer
//			if (clazz != definingClazz) {
//				meth.addAnnotation(getOverride())
//			}
//			val index = definingClazz.qualifiedName.lastIndexOf('Trait')
//			val iName = definingClazz.qualifiedName.substring(0, index)
//			val definingInterface = iName.findInterface
//			definingInterface.forAllFields [ fInfo |
//				if (!fInfo.duplicate)
//					meth.addParameter(fInfo.name, fInfo.type)
//			]
//			val thisInterface = clazz.qualifiedName.interfaceFromClassName
//			thisInterface.forAllFields [ fInfo |
//				if (!fInfo.duplicate) {
//					if (argStr.length > 0)
//						argStr.append(', ')
//					argStr.append(fInfo.name)
//				}
//			]
//			meth.docComment = 'Creates a new ' + clazz.simpleName + ' Object'
//			meth.body = [
//				'''
//					return new «clazz.simpleName»( «argStr.toString()»);
//				''']
//			meth.returnType = clazz.newTypeReference
//			meth.visibility = Visibility::PROTECTED
//		]
//	}
//
//	/** Adds a zero argument constructor to the Implementation class, the field
//	 * initial values are assigned from the corresponding interface constants. */
//	def private addZeroArgConstructor(
//		MutableClassDeclaration clazz,
//		MutableInterfaceDeclaration interf,
//		Iterable<? extends TypeReference> superTraits,
//		MutableClassDeclaration superCls
//	) {
//
//		if (clazz.findConstructor() == null) {
//			val superConstrArgs = new StringBuilder
//			val assignmentStr = new StringBuilder
//			val thisInterface = clazz.qualifiedName.interfaceFromClassName
//			val fields = thisInterface.classFields
//
//			clazz.addConstructor [ constrctr |
//				thisInterface.forAllFields [ fInfo |
//					if (!fields.contains(fInfo)) {
//						if (superConstrArgs.length > 0)
//							superConstrArgs.append(', ')
//						superConstrArgs.append(interf.simpleName + '.' + fInfo.name)
//					} else {
//						val duplicate = newBooleanArrayOfSize(1)
//						fields.forEach [ classF |
//							if (classF == fInfo && classF.duplicate)
//								duplicate.set(0, true)
//						]
//						if (!duplicate.get(0))
//							assignmentStr.append(
//								'this.' + fInfo.name + ' = ' + interf.simpleName + '.' + fInfo.name + ';\n')
//					}
//				]
//				constrctr.docComment = 'No Argument constructor, values are initialized using the constant values from ' +
//					interf.simpleName
//				constrctr.body = [
//					'''
//						«IF superConstrArgs.length > 0»
//							super( «superConstrArgs.toString()» );
//						«ENDIF»
//						«assignmentStr.toString()»
//					''']
//			]
//		}
//	}

	/** Adds a toString method using all the fields of this class, pre-pends toString of the super class. */
	def private addToString(MutableClassDeclaration clazz, MutableClassDeclaration superClass) {

		val fields = clazz.declaredFields
		if (clazz.findMethod('toString', newArrayOfSize(0)) == null) {
			clazz.addMethod('toString') [
				returnType = 'java.lang.String'.newTypeReference
				addAnnotation(getOverride())
				docComment = '{@inheritDoc}'
				body = [
					'''
						«toJavaCode(builderType)» stringData = new «toJavaCode(builderType)»();
						«IF superClass != null»
							stringData.append(super.toString()).newLine();
						«ENDIF»
						stringData.append("{").increaseIndent();
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type.array»
									stringData.newLine().append("«f.simpleName»").append(" = " + «toJavaCode(getArrays())».deepToString(«f.
							simpleName»));
								«ELSE»
									stringData.newLine().append("«f.simpleName»").append(" = " + «f.simpleName»);
								«ENDIF»
							«ENDIF»
						«ENDFOR»
						stringData.decreaseIndent().newLine().append("}");
						return stringData.toString();
					''']
			]
		}
	}

	/** Equals method implementation, uses all the fields of this class and equals method of super class. */
	def private addEquals(MutableClassDeclaration clazz, MutableClassDeclaration superClass) {

		val fields = clazz.declaredFields
		if (clazz.findMethod('equals', getObject()) == null) {
			clazz.addMethod('equals') [
				returnType = primitiveBoolean
				addAnnotation(getOverride())
				addParameter('obj', getObject())
				docComment = '{@inheritDoc}'
				body = [
					'''
						if (this == obj)
							return true;
						if (obj == null)
							return false;
						if (getClass() != obj.getClass())
							return false;
						«clazz.simpleName» other = («clazz.simpleName») obj;
						«IF superClass != null»
							if(!super.equals(other))
								return false;
						«ENDIF»
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type.primitive»
									if(«f.simpleName» != other.«f.simpleName»)
										return false;
								«ELSEIF f.type.array»
									if(!«toJavaCode(getArrays())».equals(«f.simpleName», other.«f.simpleName»))
										return false;
								«ELSE»
									if(!«f.simpleName».equals(other.«f.simpleName»))
										return false;
								«ENDIF»
							«ENDIF»
						«ENDFOR»
						return true;
					''']
			]
		}
	}

	/** Adds the hashCode method. if the class has a super class the generated methods internally calls <code>super.hashCode()</code> */
	def private addHashCode(MutableClassDeclaration clazz, MutableClassDeclaration superClass) {

		val fields = clazz.declaredFields
		if (clazz.findMethod('hashCode', newArrayOfSize(0)) == null) {
			clazz.addMethod('hashCode') [
				returnType = primitiveInt
				addAnnotation(getOverride())
				docComment = '{@inheritDoc}'
				val initValue = if (superClass == null) {
						'1'
					} else {
						'super.hashCode()'
					}
				body = [
					'''
						final int prime = 31;
						int result = «initValue»;
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type == primitiveBoolean»
									result = prime * result + («f.simpleName» ? 1231 : 1237);
								«ELSEIF #{primitiveInt, primitiveChar, primitiveByte, primitiveShort}.contains(f.type)»
									result = prime * result + «f.simpleName»;
								«ELSEIF primitiveLong == f.type»
									result = prime * result + (int) («f.simpleName» ^ («f.simpleName» >>> 32));
								«ELSEIF primitiveFloat == f.type»
									result = prime * result + Float.floatToIntBits(«f.simpleName»);
								«ELSEIF primitiveDouble == f.type»
									result = prime * result + (int) (Double.doubleToLongBits(«f.simpleName») ^ (Double.doubleToLongBits(«f.simpleName») >>> 32));
								«ELSE»
									result = prime * result + ((«f.simpleName»== null) ? 0 : «f.simpleName».hashCode());
								«ENDIF»
							«ENDIF»
						«ENDFOR»
						return result;
					''']
			]
		}
	}

	/** Generates one or more partial Static Equals method implementation */
	def private addPartialEquals(MutableClassDeclaration clazz, MutableInterfaceDeclaration interf) {

		val fields = findClass(interf.qualifiedName + 'Trait').declaredFields
		if (clazz.findMethod('equals', interf.newTypeReference, interf.newTypeReference) == null) {
			clazz.addMethod('equals') [
				static = true
				returnType = primitiveBoolean
				addParameter('obj1', interf.newTypeReference)
				addParameter('obj2', interf.newTypeReference)
				docComment = 'Compares two ' + interf.simpleName + ' objects'
				body = [
					'''
						if (obj1 == obj1)
							return true;
						if (obj1.getClass() != obj2.getClass())
							return false;
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type.primitive»
									if(obj1.get«f.simpleName.toFirstUpper»() != obj2.get«f.simpleName.toFirstUpper»())
										return false;
								«ELSEIF f.type.array»
									if(!«toJavaCode(getArrays())».equals(obj1.get«f.simpleName.toFirstUpper»(), obj2.get«f.simpleName.toFirstUpper»()))
										return false;
								«ELSE»
									if(!obj1.get«f.simpleName.toFirstUpper»().equals(obj2.get«f.simpleName.toFirstUpper»()))
										return false;
								«ENDIF»
							«ENDIF»
						«ENDFOR»
						return true;

					''']
			]
		}
	}

	def private addPartialHashCode(MutableClassDeclaration clazz, MutableInterfaceDeclaration interf) {

		val fields = findClass(interf.qualifiedName + 'Trait').declaredFields

		if (clazz.findMethod('hashCode', interf.newTypeReference) == null) {
			clazz.addMethod('hashCode') [
				returnType = primitiveInt
				static = true
				addParameter('obj', interf.newTypeReference)
				docComment = 'Returns partial hash code using the fields of ' + interf.newTypeReference.name +
					' only.'
				body = [
					'''
						final int prime = 31;
						int result = 1;
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type == primitiveBoolean»
									result = prime * result + (obj.get«f.simpleName.toFirstUpper»() ? 1231 : 1237);
								«ELSEIF #{primitiveInt, primitiveChar, primitiveByte, primitiveShort}.contains(f.type)»
									result = prime * result + obj.get«f.simpleName.toFirstUpper»();
								«ELSEIF primitiveLong == f.type»
									result = prime * result + (int) (obj.get«f.simpleName.toFirstUpper»() ^ (obj.get«f.simpleName.toFirstUpper»() >>> 32));
								«ELSEIF primitiveFloat == f.type»
									result = prime * result + Float.floatToIntBits(obj.get«f.simpleName.toFirstUpper»());
								«ELSEIF primitiveDouble == f.type»
									result = prime * result + (int) (Double.doubleToLongBits(obj.get«f.simpleName.toFirstUpper»()) ^ (Double.doubleToLongBits(obj.get«f.simpleName.toFirstUpper»()) >>> 32));
								«ELSE»
									result = prime * result + ((obj.get«f.simpleName.toFirstUpper»()== null) ? 0 : obj.get«f.simpleName.
							toFirstUpper»().hashCode());
								«ENDIF»
							«ENDIF»
						«ENDFOR»
						return result;
					''']
			]
		}
	}

	def private addPartialToString(MutableClassDeclaration clazz, MutableInterfaceDeclaration interf) {

		val fields = findClass(interf.qualifiedName + 'Trait').declaredFields
		if (clazz.findMethod('toString', interf.newTypeReference) == null) {
			clazz.addMethod('toString') [
				static = true
				addParameter('obj', interf.newTypeReference)
				returnType = 'java.lang.String'.newTypeReference
				docComment = 'Returns partial toString using the fields of ' + interf.newTypeReference.name +
					' only.'
				body = [
					'''
						«toJavaCode(builderType)» stringData = new «toJavaCode(builderType)»();
						stringData.append("{").increaseIndent();
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type.array»
									stringData.newLine().append("«f.simpleName»").append(" = " + «toJavaCode(getArrays())».deepToString(obj.get«f.
							simpleName.toFirstUpper»()));
								«ELSEIF f.type.primitive»
									stringData.newLine().append("«f.simpleName»").append(" = " + obj.get«f.simpleName.toFirstUpper»());
								«ELSE»
									stringData.newLine().append("«f.simpleName»").append(" = " + obj.get«f.simpleName.toFirstUpper»());
								«ENDIF»
							«ENDIF»
						«ENDFOR»
						stringData.decreaseIndent().newLine().append("}");
						return stringData.toString();
					''']
			]
		}
	}

	/** Adds the lambda function objects as methods in the implementation classes. */
	def private void addBehaviour(MutableClassDeclaration clazz, MutableInterfaceDeclaration interf) {

		if (!interf.extendedInterfaces.nullOrEmpty) {
			interf.extendedInterfaces.forEach [
				if (!IGNORE_INTERFACES.contains(it.name))
					clazz.addBehaviour(it.name.findInterface)
			]
		}

		/* The following logic parses the signature of the Functor object and creates method parameter list.
		 * Method implementation is a delegation to the Interface method.*/
		interf.declaredFields.forEach [ f |
			val type = f.type
			if (getFunctor().isAssignableFrom(type)) {
				var classname = type.name.removeGeneric
				val signature = getSignature(classname.forName as Class<? extends Functor>)

				if (clazz.findMethod(f.simpleName) == null) {
					clazz.addMethod(f.simpleName) [
						var isVoid = true
						var j = 0
						if (!checkType(typeof(Void), signature.get(0))) {
							val rType = signature.get(0)
							if (rType.primitive) {
								returnType = rType.newTypeReference
							} else {
								returnType = type.actualTypeArguments.get(j)
								j = j + 1
							}
							isVoid = true
						}
						// starting from third as the
						// first one is return type
						// second is the interface (this)
						var i = 2
						var args = "this"
						while (i < signature.size) {
							val param = signature.get(i)
							val paramName = 'a' + i
							args = args + ", " + paramName
							if (param.primitive) {
								addParameter(paramName, param.newTypeReference)
							} else {
								if (type.actualTypeArguments.size > j) {

									// Parameter type inferred from generics.
									addParameter(paramName, type.actualTypeArguments.get(j))
									j = j + 1
								} else {

									//This will make the parameter type to 'Object'
									addParameter(paramName, param.newTypeReference)
								}
							}
							i = i + 1
						}
						val _return = if(isVoid) 'return ' else ''
						val _args = args
						body = ['''«_return» «interf.simpleName.removeGeneric».«f.simpleName».apply(«_args»);''']
					]
				}
			}
		]
	}

	/** Adds Setters and Getters to the clazz, if the Trait Annotation indicates that the class is immutable,
	 * the generated setters will return new instance of the current class. */
	def private addMethods(MutableClassDeclaration clazz, MutableClassDeclaration superClazz,
		MutableInterfaceDeclaration inf) {

		val clazzType = clazz.newTypeReference
		// for all the direct methods in the interface.
		clazz.declaredFields.forEach [ f |

			val fName = f.simpleName
			val fType = f.type
			val getterName = 'get' + fName.toFirstUpper
			val setterName = 'set' + fName.toFirstUpper

			// a simple getter method with no args.
			if (clazz.findMethod(getterName, newArrayOfSize(0)) == null) {
				clazz.addMethod(getterName) [
					returnType = fType
					body = ['''return this.«fName»;''']
					docComment = '''Returns the value of «fName» '''
				]
			}
			if (fType.array && clazz.findMethod(getterName, primitiveInt) == null) {
				clazz.addMethod(getterName) [
					addParameter('_index', primitiveInt)
					returnType = fType.arrayComponentType
					body = [
						'''
							if(«fName» == null )
								throw new NullPointerException("«fName»");
							return this.«fName»[_index];
						''']
					docComment = '''Returns the element value of «fName» for a particular index position'''
				]
			} else if (fType.isList && clazz.findMethod(getterName, primitiveInt) == null) {
				clazz.addMethod(getterName) [
					addParameter('_index', primitiveInt)
					val types = fType.actualTypeArguments
					val rType = if(!types.nullOrEmpty) types.head else getObject()
					returnType = rType
					body = [
						'''
							if(«fName» == null )
								throw new NullPointerException("«fName»");
							return («rType.name»)this.«fName».get(_index);
						''']
					docComment = '''Returns the element value of «fName» for a particular index position'''
				]
			}
			//Create Setter method.
			if (clazz.findMethod(setterName, fType) == null) {
				clazz.addMethod(setterName) [
					addParameter(fName, fType)
					returnType = clazzType
					//Setter of immutable class calls newXXX method.
					if (inf.immutableTrait) {
						val args = new StringBuffer
						val thisInterface = clazz.qualifiedName.interfaceFromClassName
						val fields = thisInterface.classFields
						thisInterface.forAllFields [ fInfo |
							if (args.length > 0)
								args.append(', ')
							if (fields.contains(fInfo)) {
								if (fName == fInfo.name) {
									args.append(fName)
								} else {
									args.append(' this.' + fInfo.name)
								}
							} else {
								args.append(' this.get' + fInfo.name.toFirstUpper + '()')
							}
						]

						val allArgs = args
						body = [
							'''
								return new«clazz.qualifiedName.removeDots.toFirstUpper»(«allArgs»);
							''']
						docComment = '''Modifies  «fName» and returns a new instance of  «clazz.simpleName»'''

					} else {
						body = [
							'''
								this.«fName» = «fName»;
								return this;
							''']
						docComment = '''Modifies  «fName» and returns 'this' '''
					}
				]
			}
			if (fType.array) {
				if (clazz.findMethod(setterName, primitiveInt, fType) == null) {
					clazz.addMethod(setterName) [
						addParameter('_index', primitiveInt)
						val param2 = '_' + fName
						addParameter(param2, fType.arrayComponentType)
						returnType = clazzType
						body = [
							'''
								if(«fName» == null )
									throw new NullPointerException("«fName»");
								this.«fName»[_index] = «param2»;
								return this;
							''']
					]
				}
			} else if (fType.isList) {
				if (clazz.findMethod(setterName, primitiveInt, fType) == null) {
					clazz.addMethod(setterName) [
						addParameter('_index', primitiveInt)
						val param2 = '_' + fName
						val types = fType.actualTypeArguments
						val paramType = if(!types.nullOrEmpty) types.head else getObject()
						addParameter(param2, paramType)
						returnType = inf.newTypeReference
						body = [
							'''
								if(«fName» == null )
									throw new NullPointerException("«fName»");
								this.«fName».set(_index, «param2»);
								return this;
							''']
					]
				}
			}
		]
	}

	/** Adds Getters and Setter to the trait Interface. */
	def private boolean processField(FieldInfo fieldDeclaration, MutableInterfaceDeclaration interf) {

		val fieldName = fieldDeclaration.name
		val toFirstUpper = fieldName.toFirstUpper
		val fieldType = fieldDeclaration.type

		if (fieldName.charAt(0).isLowerCase && !fieldType.isFunctor) {
			val getter = 'get' + toFirstUpper
			interf.addMethod(getter) [
				returnType = fieldType
			]
			interf.addMethod('set' + toFirstUpper) [
				addParameter(fieldName, fieldType)
				returnType = interf.newTypeReference
			]
			if (fieldType.array) {
				interf.addMethod('get' + toFirstUpper) [
					addParameter('index', primitiveInt)
					returnType = fieldType.arrayComponentType
				]
				interf.addMethod('set' + toFirstUpper) [
					addParameter('index', primitiveInt)
					addParameter(fieldName, fieldType.arrayComponentType)
					returnType = interf.newTypeReference
				]
			} else if (fieldType.isList) {
				interf.addMethod('get' + toFirstUpper) [
					addParameter('index', primitiveInt)
					returnType = fieldType.actualTypeArguments.head ?: getObject()
				]
				interf.addMethod('set' + toFirstUpper) [
					val tp = fieldType.actualTypeArguments.head ?: getObject()
					addParameter('index', primitiveInt)
					addParameter(fieldName, tp)
					returnType = interf.newTypeReference
				]
			}
			return true
		}
		false
	}

	/**
	 * Method adds fields to a Trait impl class and also sets its extended class if any.
	 *
	 * A Trait implementation class contains all the fields that directly belong the corresponding Trait interface,
	 * plus the other fields in the type hierarchy above, excluding the fields of the trait class that its extended from
	 * <pre>
	 * Example :
	 * If a Trait A is extended from B and C and interface B contains more of fields than C.
	 * The Trait implementation class 'ATrait' extends class 'BTrait' and implements C.
	 * in the above example Class 'ATrait' will contain all the fields from A and C and will *not*
	 * directly contain any fields from B and its super types.
	 * </pre> */
	def private void generateTraitClassFields(MutableInterfaceDeclaration traitInterface) {
		val traitClass = traitInterface.findClass
		val fields = traitInterface.classFields
		debug(TraitProcessor, "generateTraitClassFields", traitClass,
			"Generating fields for "+traitClass.qualifiedName)
		val superClass = if(traitInterface.superInterface != null) traitInterface.superInterface.findClass

		if (superClass != null)
			traitClass.extendedClass = superClass.newTypeReference

		fields?.forEach [ fInfo |
			if (!fInfo.duplicate && fInfo.error == null) {
				traitClass.addField(fInfo.name) [
					type = fInfo.type
					if (traitInterface.immutableTrait)
						final = true
				]
				debug(TraitProcessor, "generateTraitClassFields", traitClass, 'Adding Field :' + fInfo)
			} else if (fInfo.error == null) {
				warn(TraitProcessor, "generateTraitClassFields", traitClass, 'Duplicate Field :' + fInfo + ' found in the interface hierarchy.')
			} else {
				error(TraitProcessor, "generateTraitClassFields", traitClass,
					'Duplicate Field :' + fInfo + ' found in the interface hierarchy, with different types.')
			}
		]
	}

	/** Method used by doTransform to generate the impl class. */
	def private generateTraitClassBehavior(MutableInterfaceDeclaration t) {
		val clazz = t.findClass
		debug(TraitProcessor, "generateTraitClassFields", clazz,
			"Generating code for "+clazz.qualifiedName)

		val superInterface = t.superInterface
		val superTraits = t.sortedSuperInterfaces?.filter [ superT |
			superT.name.findInterface != superInterface
		]

		val superClass = (t.superInterface?.qualifiedName + 'Trait').findClass
//		clazz.addZeroArgConstructor(t, superTraits, superClass)
//		clazz.addAllArgConstructor(superTraits)
		clazz.addMethods(superClass, t)
//		clazz.addNewMethod(t.findClass)
		clazz.addObjectMethods(superClass)

		superTraits?.forEach [
			val traitI = name.findInterface
			val traitClass = findClass(traitI.qualifiedName + 'Trait')
			if (traitClass === null) {
				error(TraitProcessor, "generateTraitClassBehavior", traitClass,
					'Invalid parent :' + traitI.qualifiedName + 'Trait not found.')
			} else {
				clazz.addPartialHashCode(traitI)
				clazz.addPartialToString(traitI)
				clazz.addPartialEquals(traitI)
			}
		]
		if (superClass != null) {
			clazz.addPartialHashCode(superInterface)
			clazz.addPartialToString(superInterface)
			clazz.addPartialEquals(superInterface)
		}

	}

//	//////////////////////////////////////////////////////////////////////////////
//	// Serialization related methods.										    //
//	//////////////////////////////////////////////////////////////////////////////
//	/* Creates the content of the Template class. */
//	def private generateTemplate(
//		MutableInterfaceDeclaration interf,
//		MutableClassDeclaration traitClass,
//		MutableClassDeclaration superClass
//	) {
//		val templateClass = findClass(interf.qualifiedName + 'Template')
//		generateTemplateMethods(traitClass, superClass, templateClass, interf, traitClass)
//
//	}
//
//	def private generateTemplateMethods(
//		MutableClassDeclaration traitClass,
//		MutableClassDeclaration superClass,
//		MutableClassDeclaration templateClass,
//		MutableInterfaceDeclaration interf,
//		MutableClassDeclaration concreteTraitClass
//	) {
//
//		val absTempl = typeof(AbstractTemplate).findTypeGlobally
//		val tClass = traitClass.newTypeReference
//		val intType = primitiveInt
//		val counter = new Counter;
//		val map = new TreeMap<Integer, TemplateField>
//
//		// Setting the base class as AbstractTemplate<TraitClass>
//		templateClass.extendedClass = absTempl.newTypeReference(traitClass.newTypeReference)
//		addFieldToTemplateClass(traitClass, templateClass, interf, intType, counter, map)
//
//		templateClass.addConstructor [ cnstr |
//			val trackingMode = if(interf.immutableTrait) 'EQUALITY' else 'IDENTITY'
//			cnstr.body = [
//				'''
//					super(null, «traitClass.qualifiedName».class, 1,
//					                    «typeof(ObjectType).name».MAP,
//					                    «typeof(TrackingType).name».«trackingMode» , 1);
//				''']
//		]
//		createWriteData(templateClass, tClass, map, interf)
//		createReadData(templateClass, tClass, traitClass, map, concreteTraitClass)
//		createSpaceRequired(templateClass, interf, tClass, traitClass, map)
//		if (!interf.immutableTrait) {
//			templateClass.addMethod('preCreate') [
//				addParameter('size', primitiveInt)
//				addAnnotation(getOverride())
//				returnType = traitClass.newTypeReference
//				body = [
//					'''
//						return new «concreteTraitClass.qualifiedName»();
//					'''
//				]
//			]
//		}
//	}
//
//	/** Creates the readData method of the template class. */
//	def private createReadData(
//		MutableClassDeclaration templateClass,
//		TypeReference tClass,
//		MutableTypeDeclaration traitClass,
//		TreeMap<Integer, TemplateField> map,
//		MutableClassDeclaration concreteTraitClass
//	) {
//
//		val unPackContextType = typeof(UnpackerContext).newTypeReference
//		val ioExceptionType = typeof(IOException).newTypeReference
//		val immutable = traitClass.qualifiedName.interfaceFromClassName.immutableTrait
//
//		templateClass.addMethod('readData') [
//			addParameter('context', unPackContextType)
//			addParameter('preCreated', tClass)
//			addParameter('size', primitiveInt)
//			exceptions = ioExceptionType
//			returnType = traitClass.newTypeReference
//			val switc = if (immutable) {
//					'''
//
//						switch (field) {
//							«FOR i : map.keySet»
//								case «map.get(i).templateFieldName»:
//									«IF primitiveBoolean == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readBoolean();
//									«ELSEIF primitiveInt == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readInt();
//									«ELSEIF primitiveByte == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readByte();
//									«ELSEIF primitiveChar == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readChar();
//									«ELSEIF primitiveDouble == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readDouble();
//									«ELSEIF primitiveFloat == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readFloat();
//									«ELSEIF primitiveLong == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readLong();
//									«ELSEIF primitiveShort == map.get(i).fieldType»
//										f_«map.get(i).fieldName» = u.readShort();
//									«ELSE»
//										f_«map.get(i).fieldName» = («map.get(i).fieldType.name»)context.objectUnpacker.readObject();
//									«ENDIF»
//									break;
//							«ENDFOR»
//							default:
//								throw new IOException("Field " + field + " unknown");
//						}
//					'''
//				} else {
//					'''
//
//						switch (field) {
//							«FOR i : map.keySet»
//								case «map.get(i).templateFieldName»:
//									«IF primitiveBoolean == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readBoolean());
//									«ELSEIF primitiveInt == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readInt());
//									«ELSEIF primitiveByte == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readByte());
//									«ELSEIF primitiveChar == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readChar());
//									«ELSEIF primitiveDouble == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readDouble());
//									«ELSEIF primitiveFloat == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readFloat());
//									«ELSEIF primitiveLong == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readLong());
//									«ELSEIF primitiveShort == map.get(i).fieldType»
//										value.set«map.get(i).fieldName.toFirstUpper»(u.readShort());
//									«ELSE»
//										value.set«map.get(i).fieldName.toFirstUpper»((«map.get(i).fieldType.name»)context.objectUnpacker.readObject());
//									«ENDIF»
//									break;
//							«ENDFOR»
//							default:
//								throw new IOException("Field " + field + " unknown");
//						}
//					'''
//				}
//			body = [
//				'''
//
//				«tClass.simpleName» value = preCreated ;
//				final «typeof(Unpacker).name» u = context.unpacker;
//				readHeaderValue(context, value, size);
//				int fields = size;
//
//				«IF immutable»
//					«FOR i : map.keySet»
//						«toJavaCode(map.get(i).fieldType)» f_«map.get(i).fieldName» = «map.get(i).interf.simpleName».«map.get(i).fieldName»;
//					«ENDFOR»
//				«ELSE»
//					if(value == null){
//						value = new «concreteTraitClass.simpleName»();
//					}
//				«ENDIF»
//
//
//				while (fields-- > 0) {
//					final int field = u.readInt();
//					«switc»
//				}
//				«IF immutable»
//					return new «concreteTraitClass.simpleName»(
//					«FOR i : map.keySet SEPARATOR ','»
//						f_«map.get(i).fieldName»
//					«ENDFOR»);
//				«ELSE»
//					return 	value;
//				«ENDIF»'''
//			]
//		]
//	}
//
//	/** Creates the getSpaceRequired method of the template class. */
//	def private createSpaceRequired(
//		MutableClassDeclaration templateClass,
//		MutableInterfaceDeclaration interf,
//		TypeReference tClass,
//		MutableTypeDeclaration traitClass,
//		TreeMap<Integer, TemplateField> map
//	) {
//
//		val intType = primitiveInt
//		val packContextType = typeof(PackerContext).newTypeReference
//
//		templateClass.addMethod('getSpaceRequired') [
//			addParameter('context', packContextType)
//			addParameter('value', tClass)
//			returnType = intType
//			body = [
//				'''
//				int result = 0 ;
//					«FOR i : map.keySet»
//						«IF map.get(i).fieldType.primitive || map.get(i).fieldType.wrapper»
//							result += value.«map.get(i).accessor» == «toJavaCode(interf.qualifiedName.newTypeReference)».«map.get(i).fieldName» ?  0 :1 ;
//						«ELSE»
//							result += «toJavaCode(TYPE_OBJECTS)».deepEquals(value.«map.get(i).accessor», «toJavaCode(interf.qualifiedName.newTypeReference)».«map.get(i).
//					fieldName») ?  0 :1 ;
//						«ENDIF»
//					«ENDFOR»
//					return result;'''
//			]
//		]
//	}
//
//	def private createWriteData(
//		MutableClassDeclaration templateClass,
//		TypeReference tClass,
//		TreeMap<Integer, TemplateField> map,
//		MutableInterfaceDeclaration interf
//	) {
//
//		val intType = primitiveInt
//		val packContextType = typeof(PackerContext).newTypeReference
//		val ioExceptionType = typeof(IOException).newTypeReference
//
//		templateClass.addMethod('writeData') [
//			addParameter('context', packContextType)
//			addParameter('size', intType)
//			addParameter('value', tClass)
//			exceptions = ioExceptionType
//			body = [
//				'''
//
//				final «typeof(Packer).name» p = context.packer;
//				«FOR i : map.keySet»
//					«IF map.get(i).fieldType.primitive»
//						if (value.«map.get(i).accessor» != «toJavaCode(interf.qualifiedName.newTypeReference)».«map.get(i).fieldName») {
//							p.writeInt(«map.get(i).templateFieldName»);
//							«IF primitiveBoolean == map.get(i).fieldType»
//								p.writeBoolean(value.«map.get(i).accessor»);
//							«ELSEIF primitiveInt == map.get(i).fieldType»
//								p.writeInt(value.«map.get(i).accessor»);
//							«ELSEIF primitiveByte == map.get(i).fieldType»
//								p.writeByte(value.«map.get(i).accessor»);
//							«ELSEIF primitiveChar == map.get(i).fieldType»
//								p.writeChar(value.«map.get(i).accessor»);
//							«ELSEIF primitiveDouble == map.get(i).fieldType»
//								p.writeDouble(value.«map.get(i).accessor»);
//							«ELSEIF primitiveFloat == map.get(i).fieldType»
//								p.writeFloat(value.«map.get(i).accessor»);
//							«ELSEIF primitiveLong == map.get(i).fieldType»
//								p.writeLong(value.«map.get(i).accessor»);
//							«ELSEIF primitiveShort == map.get(i).fieldType»
//								p.writeShort(value.«map.get(i).accessor»);
//							«ENDIF»
//						}
//					«ELSEIF map.get(i).fieldType.array»
//						if (!«toJavaCode(TYPE_OBJECTS)».deepEquals(value.«map.get(i).accessor», «toJavaCode(interf.qualifiedName.newTypeReference)».«map.get(i).fieldName»)) {
//							p.writeInt(«map.get(i).templateFieldName»);
//							context.objectPacker.writeObject(value.«map.get(i).accessor»);
//						}
//					«ELSE»
//						if (!«toJavaCode(TYPE_OBJECTS)».equals(value.«map.get(i).accessor», «toJavaCode(
//					interf.qualifiedName.newTypeReference)».«map.get(i).fieldName»)) {
//							p.writeInt(«map.get(i).templateFieldName»);
//							context.objectPacker.writeObject(value.«map.get(i).accessor»);
//						}
//					«ENDIF»
//				«ENDFOR»'''
//			]
//		]
//	}
//
//	/** Populates a map with field information and adds required constants to the Template class. */
//	def private addFieldToTemplateClass(MutableClassDeclaration cls, MutableClassDeclaration templateClass,
//		MutableInterfaceDeclaration intf, TypeReference intType, Counter counter, Map<Integer, TemplateField> map) {
//
//		val thisInterface = cls.qualifiedName.interfaceFromClassName
//		thisInterface.forAllFields [ fInfo |
//			if (!fInfo.duplicate) {
//				val tf = new TemplateField
//				tf.fieldName = fInfo.name
//				tf.templateFieldName = 'FIELD_' + fInfo.name.toUpperCase
//				tf.fieldType = fInfo.type
//				tf.accessor = 'get' + fInfo.name.toFirstUpper + '()'
//				tf.mutator = 'set' + fInfo.name.toFirstUpper
//				tf.interf = intf
//				map.put(counter.count, tf)
//				val count = counter.count
//				templateClass.addField(tf.templateFieldName) [
//					type = intType
//					static = true
//					final = true
//					initializer = [
//						'''«count»'''
//					]
//				]
//				counter.count = counter.count + 1
//			}
//		]
//	}

	//////////////////////////////////////////////////////////////////////////////
	// Cloning implementation incomplete										//
	//////////////////////////////////////////////////////////////////////////////
	/* TODO - not fully implemented. */
	@SuppressWarnings("unused")
	def private addCloneMethod(MutableClassDeclaration clazz, TypeReference superClass) {

		val fields = clazz.declaredFields
		val MutableClassDeclaration superCls = if(superClass != null) findClass(superClass.name)

		val params = new StringBuilder
		if (clazz.findMethod('clone', newArrayOfSize(0)) == null) {
			clazz.addMethod('clone') [ m |
				fields?.forEach [ f |
					if (!f.type.functor) {
						if (params.length > 0)
							params.append(', ')
						if (f.type.primitive || f.type.wrapper || f.type.string) {
							params.append(f.simpleName)
						} else {
							params.append(f.simpleName + '.clone()')
						}
					}
				]
				superCls?.declaredFields?.forEach [ f |
					if (!f.type.isFunctor) {
						if (params.length > 0)
							params.append(', ')
						if (f.type.primitive || f.type.wrapper || f.type.string) {
							params.append(f.simpleName)
						} else {
							if (f.type.array) {
								val tp = f.type.arrayComponentType

								// array shallow copy is fine for primitive, wrapper or String arrays
								if (tp.primitive || tp.wrapper || tp.string) {
									params.append(f.simpleName + '.clone()')
								} else {
									// TODO
								}
							}
							if (f.type.isList) {
								val tp = f.type.arrayComponentType

								// array shallow copy is fine for primitive, wrapper or String arrays
								if (tp.primitive || tp.wrapper || tp.string)
									params.append(f.simpleName + '.clone()')
							}
						}
					}
				]
				m.docComment = 'Returns the clone of this object.'
				m.returnType = clazz.newTypeReference
				m.body = [
					'''
						return new «clazz.simpleName»( «params.toString()» );
					''']
			]
		}
	}

	/** Register new types, to be generated later. */
	override void register(InterfaceDeclaration td, RegisterGlobalsContext context) {
		val traitName = td.qualifiedName + "Trait"
		if (findTypeGlobally(traitName) === null) {
			context.registerClass(traitName)
			warn(TraitProcessor, "register", td, "Registering Class: "+traitName)
//			context.registerClass(td.qualifiedName + "Template")
//			warn(TraitProcessor, "register", td, td.qualifiedName)
		}
	}

	/** Transform types, new or old. */
	override void transform(MutableInterfaceDeclaration mtd, TransformationContext context) {
		//Add getters and Setters to interface.
		// TODO If using inheritance, we should return the "update" the return-type
		// of the generated property setters. Either through re-declaration, or
		// through an additional generic parameter
		val remove = <MutableFieldDeclaration>newArrayList()
		mtd.forAllFields [ f |
			if (mtd == f.interf && !f.duplicate)
				if (processField(f, mtd)) {
					remove.add(f.field)
				}
		]
		// Add fields to trait impl classes
		generateTraitClassFields(mtd)
		// Add getters, setters, equals, hashcode methods to trait classes
		generateTraitClassBehavior(mtd)
		mtd.findClass.implementedInterfaces = #[mtd.newTypeReference]
		// Add methods corresponding to lambda (Functor) members
		val traitClass = findClass(mtd.qualifiedName + 'Trait')
		traitClass.addBehaviour(mtd)
		warn(TraitProcessor, "transform", traitClass, traitClass.qualifiedName+":\n"+traitClass.describeTypeDeclaration(context))
//		// Generate serialization template
//		val superClass = mtd.superInterface?.findClass
//		generateTemplate(traitClass, superClass)
		for (f : remove) {
			f.remove()
		}
	}
}
