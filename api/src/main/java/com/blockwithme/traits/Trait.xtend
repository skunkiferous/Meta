package com.blockwithme.traits

import com.blockwithme.fn.util.Functor
//import com.blockwithme.msgpack.Packer
//import com.blockwithme.msgpack.Unpacker
//import com.blockwithme.msgpack.templates.AbstractTemplate
//import com.blockwithme.msgpack.templates.ObjectType
//import com.blockwithme.msgpack.templates.PackerContext
//import com.blockwithme.msgpack.templates.TrackingType
//import com.blockwithme.msgpack.templates.UnpackerContext
import com.blockwithme.traits.util.IndentationAwareStringBuilder
import java.io.IOException
import java.io.Serializable
import java.util.Arrays
import java.util.HashSet
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.Objects
import java.util.Set
import java.util.TreeMap
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsParticipant
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility

import static com.blockwithme.fn.util.Util.*

import static extension java.lang.Character.*
import static extension java.lang.Class.*
import com.blockwithme.fn1.ProcObject

import static extension com.blockwithme.meta.annotations.ProcessorUtil.*


/**
 * Traits are interfaces with code (state/fields are generated implicitly).
 * The main benefit is that it allows a kind of multiple inheritance. Each
 * trait can model some aspect/feature of an entity/type, and a single entity/type
 * can implement many different aspects/features. Traits are interfaces containing,
 * in addition to normal constants and methods declarations, "property constants" and
 * Closures, and are annotated with a @Trait annotation.
 *
 * The generated Trait class can be mutable or immutable depending on the 'immutable'
 * parameter passed to the class.
 *
 * All the super interfaces of a Trait interface should also be Trait interfaces.
 *
 * @author tarung */
@Active(typeof(TraitProcessor))
annotation Trait {
	/** If the immutable it true all fields are final,
	 * and setter methods will return a new instance*/
	boolean immutable = false

}

/** A Temp class used to get a <code>count</code> output from a lambda function. */
class Counter {
	package int count
}

/** A Temp class used to get a <code>boolean</code> output from a lambda function. */
class BooleanFlag {
	package boolean value
}

/**
 * The Actual Annotation processor for Trait Annotation. @Trait can be applied on interfaces only hence this class processes
 * MutableInterfaceDeclaration
 *
 * Register Global phase registers two new classes for each Trait interface XYATrait class and XYZTemplate class.
 * Transformation phase generates the implementation of these classes.
 */
class TraitProcessor implements TransformationParticipant<MutableInterfaceDeclaration>, RegisterGlobalsParticipant<InterfaceDeclaration> {

	/** Register Global phase registers two new classes for each Trait
	 * interface XYATrait class and XYZTemplate class. */
	override doRegisterGlobals(List<? extends InterfaceDeclaration> annotatedSourceElements,
		extension RegisterGlobalsContext context) {
		annotatedSourceElements.forEach [
			val className = it.qualifiedName + "Trait"
			registerClass(className)
			registerClass(it.qualifiedName + "Template")
		]
	}

	/** Performs Code generation for an interface annotated with @Trait annotation. This method delegates to TraitProcessorUtil
	 * for actual code generation.*/
	override doTransform(List<? extends MutableInterfaceDeclaration> interfaces, extension TransformationContext context) {
		new TraitProcessorUtil(interfaces, context).doTransform()
	}
}

/** Temp data structure used for Template generation. */
class TemplateField {

	package String fieldName

	package String accessor

	package String mutator

	package String templateFieldName

	package TypeReference fieldType

	package MutableInterfaceDeclaration interf

}

/** Class that actually performs the code generation for Traits,
 * An object of this class is created inside TraitProcessor and the control
 is delegated to this class */
class TraitProcessorUtil {

	/** Trait Interfaces to be processed, this list comes form the Annotation processor.*/
	val List<? extends MutableInterfaceDeclaration> interfaces

	/** The Transformation Context that comes for Annotation Processor. */
	val extension TransformationContext context

	/** The following type references are resolved at the time of construction ( hence not static) */
	val Type ANNOTATION_OVERRIDE
	val Type ANNOTATION_TRAIT
	val TypeReference TYPE_FUNCTOR
	val TypeReference TYPE_STRING
	val TypeReference TYPE_OBJECT
	val TypeReference PRIM_BOOLEAN_TYPE
	val TypeReference TYPE_LIST
	val TypeReference PRIM_INT_TYPE
	val TypeReference TYPE_BUILDER
	val TypeReference TYPE_ARRAYS
	val TypeReference TYPE_OBJECTS

	/** The trait can extend from any of the following interfaces,
	 * when found in the type hierarchy, these interfaces are ignored. */
	static Set<String> IGNORE_INTERFACES = #{typeof(Serializable).name, typeof(Cloneable).name}
//
//	/** Utility method that finds an interface in the global context, returns null if not found */
//	def private findInterface(String name) {
//		val found = findTypeGlobally(name)
//		if (found instanceof MutableInterfaceDeclaration)
//			found as MutableInterfaceDeclaration
//		else
//			null
//	}
//
//	/** Utility method that finds a class in the global context, returns null if not found */
//	def private findClass(String name) {
//		val found = findTypeGlobally(name)
//		if (found instanceof MutableClassDeclaration)
//			found as MutableClassDeclaration
//		else
//			null
//	}

	/** Utility method checks if a type is a Functor type. */
	def private isFunctor(TypeReference fieldType) {
		(TYPE_FUNCTOR).isAssignableFrom(fieldType)
	}

	/** Utility method checks if a type is a String type. */
	def private isString(TypeReference fieldType) {
		(TYPE_STRING).isAssignableFrom(fieldType)
	}

	/** Checks if fieldType is of 'java.util.List' type. */
	def private isList(TypeReference fieldType) {
		if (fieldType.actualTypeArguments.size > 0) {
			(TYPE_LIST).isAssignableFrom(fieldType.name.removeGeneric.newTypeReference)
		} else
			(TYPE_LIST).isAssignableFrom(fieldType)
	}

	/** A Validator method to check if interface okay to be a trait
	 * i.e. it should be annotated with @Trait and
	 * should not have any methods of its own.
	 *
	 * TODO This method has some problems doesn't work atm. */
	@SuppressWarnings("unused")
	def private boolean isValidTrait(MutableInterfaceDeclaration _interface) {
		val valid = new BooleanFlag
		valid.value = _interface.findAnnotation(ANNOTATION_TRAIT) != null

		//		if(valid.value){
		//			_interface.sortedSuperInterfaces?.forEach[interf|
		//				if (!interf.name.findInterface.isValidTrait)
		//					valid.value = false
		//			]
		//		}

		valid.value

	}

	/** Utility method to check if _interface is immutable depending on the 'immutable' parameter passed
	 * to its @Trait annotation */
	def boolean isImmutableTrait(MutableInterfaceDeclaration _interface){
		val ann = _interface.findAnnotation(ANNOTATION_TRAIT)
		var result = false
		if(ann != null){
			result = Boolean::valueOf(ann.getValue('immutable').toString)
		}
		result
	}

	/** Utility Method to find if class has a super class that is not an object */
	def private hasSuper(MutableClassDeclaration definingClazz) {
		definingClazz.extendedClass != null && definingClazz.extendedClass != TYPE_OBJECT
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
				val duplicate = new BooleanFlag
				val error = new BooleanFlag
				if (sInterface != null) {
					for (superI : sInterface) {
						superI.name.findInterface.forAllFields [
							if (f.simpleName == name) {
								if (f.type == type) {
									duplicate.value = true;
								} else {
									error.value = true
								}
							}
						]
					}
				}
				if (!f.type.isFunctor) {
					val fieldInfo = new FieldInfo(f.simpleName, f.type, interf)
					if (duplicate.value) {
						fieldInfo.duplicate = true
					} else if (error.value) {
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
				val counter = new Counter
				superI.name.findInterface.forAllFields [
					counter.count = counter.count + 1
				]
				if (counter.count > superClassFields) {
					result = superI.name.findInterface
					superClassFields = counter.count
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

	/**
	 * Add all arguments constructors to a particular Trait class.
	 *
	 *  @param clazz class to which the constructor is added.
	 *  @param superTraits a list of super Trait interfaces if any
	 * (excluding the heaviest interface from which the clazz will be inherited)  */
	def private addAllArgConstructor(
		MutableClassDeclaration clazz,
		Iterable<? extends TypeReference> superTraits
	) {

		val superConstrArgs = new StringBuilder
		val assignmentStr = new StringBuilder
		val thisInterface = clazz.qualifiedName.interfaceFromClassName
		val fields = thisInterface.classFields

		clazz.addConstructor [ constrctr |
			thisInterface.forAllFields [ fInfo |
				val duplicate = new BooleanFlag
				if (fields.contains(fInfo)) {
					fields.forEach [ classF |
						if (classF == fInfo && classF.duplicate)
							duplicate.value = true
					]
					if (!duplicate.value)
						assignmentStr.append('this.' + fInfo.name + ' = ' + fInfo.name + ';\n')
				} else {
					if (superConstrArgs.length > 0)
						superConstrArgs.append(', ')
					superConstrArgs.append(fInfo.name)
				}
				if (!duplicate.value)
					constrctr.addParameter(fInfo.name, fInfo.type)
			]
			constrctr.docComment = 'The all Argument Constructor'
			constrctr.body = [
				'''
					«IF superConstrArgs.length > 0»
						super( «superConstrArgs.toString()» );
					«ENDIF»
					«assignmentStr.toString()»
				''']
		]
	}

	/**
	 * Adds 'newXYZ' methods, where 'XYZ' is a string generated from fully qualified name of 'definingClazz', where
	 * 'definingClazz' is either 'clazz' itself or any of its super classes. This method is added to 'clazz',
	 * methods parameters are same as the all arg constructor of 'definingClazz'. one 'newXYZ' method is generated
	 * for the current and one each for all its super Trait classes.
	 *
	 * <pre>
	 * 	 Each method -
	 *   	Takes arguments same as the constructor of the defining class.
	 *   	Return a new instance of the *current* Trait class.
	 * </pre> */
	def private void addNewMethod(MutableClassDeclaration clazz, MutableClassDeclaration definingClazz) {

		val MutableClassDeclaration superClass = if (definingClazz.hasSuper)
				definingClazz.extendedClass.name.findClass
		if (superClass != null) {
			clazz.addNewMethod(superClass)
		}
		clazz.addMethod("new" + definingClazz.qualifiedName.removeDots.toFirstUpper) [ meth |
			val argStr = new StringBuffer
			if (clazz != definingClazz) {
				meth.addAnnotation(ANNOTATION_OVERRIDE)
			}
			val index = definingClazz.qualifiedName.lastIndexOf('Trait')
			val iName = definingClazz.qualifiedName.substring(0, index)
			val definingInterface = iName.findInterface
			definingInterface.forAllFields [ fInfo |
				if (!fInfo.duplicate)
					meth.addParameter(fInfo.name, fInfo.type)
			]
			val thisInterface = clazz.qualifiedName.interfaceFromClassName
			thisInterface.forAllFields [ fInfo |
				if (!fInfo.duplicate) {
					if (argStr.length > 0)
						argStr.append(', ')
					argStr.append(fInfo.name)
				}
			]
			meth.docComment = 'Creates a new ' + clazz.simpleName + ' Object'
			meth.body = [
				'''
					return new «clazz.simpleName»( «argStr.toString()»);
				''']
			meth.returnType = clazz.newTypeReference
			meth.visibility = Visibility::PROTECTED
		]
	}

	/** Adds a zero argument constructor to the Implementation class, the field
	 * initial values are assigned from the corresponding interface constants. */
	def private addZeroArgConstructor(
		MutableClassDeclaration clazz,
		MutableInterfaceDeclaration interf,
		Iterable<? extends TypeReference> superTraits,
		MutableClassDeclaration superCls
	) {

		if (clazz.findConstructor() == null) {
			val superConstrArgs = new StringBuilder
			val assignmentStr = new StringBuilder
			val thisInterface = clazz.qualifiedName.interfaceFromClassName
			val fields = thisInterface.classFields

			clazz.addConstructor [ constrctr |
				thisInterface.forAllFields [ fInfo |
					if (!fields.contains(fInfo)) {
						if (superConstrArgs.length > 0)
							superConstrArgs.append(', ')
						superConstrArgs.append(interf.simpleName + '.' + fInfo.name)
					} else {
						val duplicate = new BooleanFlag
						fields.forEach [ classF |
							if (classF == fInfo && classF.duplicate)
								duplicate.value = true
						]
						if (!duplicate.value)
							assignmentStr.append(
								'this.' + fInfo.name + ' = ' + interf.simpleName + '.' + fInfo.name + ';\n')
					}
				]
				constrctr.docComment = 'No Argument constructor, values are initialized using the constant values from ' +
					interf.simpleName
				constrctr.body = [
					'''
						«IF superConstrArgs.length > 0»
							super( «superConstrArgs.toString()» );
						«ENDIF»
						«assignmentStr.toString()»
					''']
			]
		}
	}

	/** Adds a toString method using all the fields of this class, pre-pends toString of the super class. */
	def private addToString(MutableClassDeclaration clazz, MutableClassDeclaration superClass) {

		val fields = clazz.declaredFields
		if (clazz.findMethod('toString', newArrayOfSize(0)) == null) {
			clazz.addMethod('toString') [
				returnType = 'java.lang.String'.newTypeReference
				addAnnotation(ANNOTATION_OVERRIDE)
				docComment = '{@inheritDoc}'
				body = [
					'''
						«toJavaCode(TYPE_BUILDER)» stringData = new «toJavaCode(TYPE_BUILDER)»();
						«IF superClass != null»
							stringData.append(super.toString()).newLine();
						«ENDIF»
						stringData.append("{").increaseIndent();
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type.array»
									stringData.newLine().append("«f.simpleName»").append(" = " + «toJavaCode(TYPE_ARRAYS)».deepToString(«f.
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
		if (clazz.findMethod('equals', TYPE_OBJECT) == null) {
			clazz.addMethod('equals') [
				returnType = PRIM_BOOLEAN_TYPE
				addAnnotation(ANNOTATION_OVERRIDE)
				addParameter('obj', TYPE_OBJECT)
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
									if(!«toJavaCode(TYPE_ARRAYS)».equals(«f.simpleName», other.«f.simpleName»))
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
				addAnnotation(ANNOTATION_OVERRIDE)
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
				returnType = PRIM_BOOLEAN_TYPE
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
									if(!«toJavaCode(TYPE_ARRAYS)».equals(obj1.get«f.simpleName.toFirstUpper»(), obj2.get«f.simpleName.toFirstUpper»()))
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
						«toJavaCode(TYPE_BUILDER)» stringData = new «toJavaCode(TYPE_BUILDER)»();
						stringData.append("{").increaseIndent();
						«FOR f : fields»
							«IF !f.type.isFunctor»
								«IF f.type.array»
									stringData.newLine().append("«f.simpleName»").append(" = " + «toJavaCode(TYPE_ARRAYS)».deepToString(obj.get«f.
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
			if (TYPE_FUNCTOR.isAssignableFrom(type)) {
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
			if (fType.array && clazz.findMethod(getterName, PRIM_INT_TYPE) == null) {
				clazz.addMethod(getterName) [
					addParameter('_index', PRIM_INT_TYPE)
					returnType = fType.arrayComponentType
					body = [
						'''
							if(«fName» == null )
								throw new NullPointerException("«fName»");
							return this.«fName»[_index];
						''']
					docComment = '''Returns the element value of «fName» for a particular index position'''
				]
			} else if (fType.isList && clazz.findMethod(getterName, PRIM_INT_TYPE) == null) {
				clazz.addMethod(getterName) [
					addParameter('_index', PRIM_INT_TYPE)
					val types = fType.actualTypeArguments
					val rType = if(!types.nullOrEmpty) types.head else TYPE_OBJECT
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
				if (clazz.findMethod(setterName, PRIM_INT_TYPE, fType) == null) {
					clazz.addMethod(setterName) [
						addParameter('_index', PRIM_INT_TYPE)
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
				if (clazz.findMethod(setterName, PRIM_INT_TYPE, fType) == null) {
					clazz.addMethod(setterName) [
						addParameter('_index', PRIM_INT_TYPE)
						val param2 = '_' + fName
						val types = fType.actualTypeArguments
						val paramType = if(!types.nullOrEmpty) types.head else TYPE_OBJECT
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
	def private processField(FieldInfo fieldDeclaration, MutableInterfaceDeclaration interf) {

		val fieldName = fieldDeclaration.name
		val fieldType = fieldDeclaration.type

		if (fieldName.charAt(0).isLowerCase && !fieldType.isFunctor) {

			val getter = 'get' + fieldName.toFirstUpper
			interf.addMethod(getter) [
				returnType = fieldType
			]
			interf.addMethod('set' + fieldName.toFirstUpper) [
				addParameter(fieldName, fieldType)
				returnType = interf.newTypeReference
			]
		}
		if (fieldType.array) {
			interf.addMethod('get' + fieldName.toFirstUpper) [
				addParameter('index', PRIM_INT_TYPE)
				returnType = fieldType.arrayComponentType
			]
			interf.addMethod('set' + fieldName.toFirstUpper) [
				addParameter('index', PRIM_INT_TYPE)
				addParameter(fieldName, fieldType.arrayComponentType)
				returnType = interf.newTypeReference
			]
		} else if (fieldType.isList) {
			interf.addMethod('get' + fieldName.toFirstUpper) [
				addParameter('index', PRIM_INT_TYPE)
				returnType = fieldType.actualTypeArguments.head ?: TYPE_OBJECT
			]
			interf.addMethod('set' + fieldName.toFirstUpper) [
				val tp = fieldType.actualTypeArguments.head ?: TYPE_OBJECT
				addParameter('index', PRIM_INT_TYPE)
				addParameter(fieldName, tp)
				returnType = interf.newTypeReference
			]
		}
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
		val superClass = if(traitInterface.superInterface != null) traitInterface.superInterface.findClass

		if (superClass != null)
			traitClass.extendedClass = superClass.newTypeReference

		val fields = traitInterface.classFields

		fields?.forEach [
			if (!duplicate && error == null) {
				traitClass.addField(name) [
					type = type
					if (traitInterface.immutableTrait)
						final = true
				]
			} else if (error == null) {
				traitClass.addWarning('Duplicate Field :' + it + ' found in the interface hierarchy.')
			} else {
				traitClass.addError(
					'Duplicate Field :' + it + ' found in the interface hierarchy, with different types.')
			}
		]
	}

	/** Method used by doTransform to generate the impl class. */
	def private generateTraitClassBehavior(MutableInterfaceDeclaration t) {

		val clazz = t.findClass
		val superInterface = t.superInterface
		val superTraits = t.sortedSuperInterfaces?.filter [ superT |
			superT.name.findInterface != superInterface
		]

		val superClass = (t.superInterface?.qualifiedName + 'Trait').findClass
		clazz.addZeroArgConstructor(t, superTraits, superClass)
		clazz.addAllArgConstructor(superTraits)
		clazz.addMethods(superClass, t)
		clazz.addNewMethod(t.findClass)
		clazz.addObjectMethods(superClass)

		superTraits?.forEach [
			val traitI = name.findInterface
			clazz.addPartialHashCode(traitI)
			clazz.addPartialToString(traitI)
			clazz.addPartialEquals(traitI)
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
//		val intType = PRIM_INT_TYPE
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
//				addParameter('size', PRIM_INT_TYPE)
//				addAnnotation(ANNOTATION_OVERRIDE)
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
//			addParameter('size', PRIM_INT_TYPE)
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
//		val intType = PRIM_INT_TYPE
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
//		val intType = PRIM_INT_TYPE
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

	/** Public constructor for this class. */
	new(List<? extends MutableInterfaceDeclaration> interfaces, extension TransformationContext context) {

		this.interfaces = interfaces
		this.context = context

		ANNOTATION_OVERRIDE = typeof(Override).findTypeGlobally
		ANNOTATION_TRAIT = typeof(Trait).findTypeGlobally
		TYPE_FUNCTOR = typeof(Functor).newTypeReference
		TYPE_STRING = typeof(String).newTypeReference
		TYPE_OBJECT = typeof(Object).newTypeReference
		PRIM_BOOLEAN_TYPE = typeof(boolean).newTypeReference
		TYPE_LIST = typeof(List).newTypeReference
		PRIM_INT_TYPE = typeof(int).newTypeReference
		TYPE_BUILDER = typeof(IndentationAwareStringBuilder).newTypeReference
		TYPE_ARRAYS = typeof(Arrays).newTypeReference
		TYPE_OBJECTS = typeof(Objects).newTypeReference

	}

	/** The public method that actually performs Code generation for an interface annotated with @Trait.*/
	def doTransform() {

		val valid = new BooleanFlag
		valid.value = true

		// Perform validations.
		interfaces.forEach [
			if (!isValidTrait) {
				addError('Invalid trait interface')
				valid.value = false
			}
		]

		if (valid.value) {

			//Add getters and Setters to interface.
			interfaces.forEach [ interf |
				interf.forAllFields [
					if (interf == interf && !duplicate)
						processField(it, interf)
				]
			]

			// Add fields to trait impl classes
			interfaces.forEach [
				generateTraitClassFields
			]

			// Add getters, setters, equals, hashcode methods to trait classes
			interfaces.forEach [
				generateTraitClassBehavior
				findClass.implementedInterfaces = #[newTypeReference]
			]

			// Add methods corresponding to lambda (Functor) members
			interfaces.forEach [
				val traitClass = findClass(qualifiedName + 'Trait')
				val superClass = superInterface?.findClass
				traitClass.addBehaviour(it)
				// Generate serialization template
//				generateTemplate(traitClass, superClass)
			]
		}
	}
}

