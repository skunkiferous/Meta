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
package com.blockwithme.meta

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtext.xbase.lib.Procedures

import static extension de.oehme.xtend.contrib.macro.CommonQueries.*
import de.oehme.xtend.contrib.macro.CommonTransformations
import java.lang.annotation.ElementType
import java.lang.annotation.Target

/**
 * Annotates an interface declared in a C-style-struct syntax
 * into a full-blown bean, including, in particular, defining the type
 * and it's properties using the Meta API.
 *
 * @author monster
 */
@Active(BeanProcessor)
@Target(ElementType.TYPE)
annotation Bean {
}

/**
 * Process classes annotated with @Bean
 *
 * REGISTER:
 * 0) Type must be an interface
 * 1) For each type, scan the type hierarchy, recording field names and types along the way
 * 2) (atm) Each Type in the hierarchy must either contain only fields without initializers, or be one of the Base types (Bean or Entity)
 * 3) No (case insensitive) "simple" type name must be used more then once within Hierarchy+dependencies.
 * 4) No (case insensitive) "simple" field name must be used more then once within Hierarchy+dependencies.
 * 5) For each type, an Impl type under impl package is registered, if not defined yet
 * 6) For each type, a type Provider under impl package is registered, if not defined yet
 * 7) For each type property, an Accessor type under impl package is declared, if not defined yet
 * 8) For each type *package*, a Meta interface is declared, if not defined yet
 * GENERATE:
 * 9) For each type, the fields are replaced with getters and setters
 * 10) Meta is created
 * 11) A builder is created in Meta for that package
 * 12) For each type property, a property accessor class is generated
 * 14) For each type property, a property object in the "Meta" interface is generated.
 * 14) For each type, a type Provider under impl package is created.
 * 15) For each type, following the properties, a type instance is created.
 * 16) After all types, a package meta-object is created.
 * 17) The list of dependencies for the Hierarchy is computed.
 * 18) After the package, the hierarchy is created.
 * 19) The Impl extends either the impl of the first parent, or BaseImpl or EntityImpl appropriatly
 * 20) For all getters and setters in type, implementations are generated in Impl
 * 21) If we have more then one parent, find out all missing properties
 * 22) Add impl to all missing properties in Impl
 *
 * @author monster
 */
class BeanProcessor extends AbstractClassProcessor {

	override doRegisterGlobals(ClassDeclaration cls, RegisterGlobalsContext context) {
		if(!cls.compilationUnit.sourceTypeDeclarations.exists[qualifiedName == cls.builderClassName]) {
			context.registerClass(cls.builderClassName)
		}
	}

	override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
		val extension transformations = new CommonTransformations(context)
		if(cls.extendedClass != object)
			cls.addError("Inheritance does not play well with immutability")

		cls.final = true
		val builder = cls.builderClass(context) => [
			final = true
			addMethod("build") [
				returnType = cls.newTypeReference
				body = [
					'''
						return new «cls.simpleName»(«cls.persistentState.join(",")[simpleName]»);
					''']
			]
			cls.persistentState.forEach [ field |
				addMethod(field.simpleName) [
					addParameter(field.simpleName, field.type)
					returnType = cls.builderClass(context).newTypeReference
					body = [
						'''
							this.«field.simpleName» = «field.simpleName»;
							return this;
						''']
				]
				addField(field.simpleName) [
					type = field.type
				]
			]
		]

		cls.addMethod("build") [
			static = true
			returnType = cls.newTypeReference
			addParameter("init", Procedures$Procedure1.newTypeReference(builder.newTypeReference))
			body = [
				'''
					«cls.builderClassName» builder = builder();
					init.apply(builder);
					return builder.build();
				''']
		]
		cls.addMethod("builder") [
			returnType = cls.builderClass(context).newTypeReference
			static = true
			body = [
				'''
					return new «cls.builderClassName»();
				''']
		]

		cls.persistentState.forEach [ field |
			field.addGetter
			//TODO https://bugs.eclipse.org/bugs/show_bug.cgi?id=404167
			cls.addField(field.simpleName) [
				type = field.type
				initializer = field.initializer
			]
			field.remove
		]

		if(!cls.hasDataConstructor) cls.addDataConstructor
		if(!cls.hasEquals) cls.addDataEquals
		if(!cls.hasHashCode) cls.addDataHashCode
		if(!cls.hasToString) cls.addDataToString
	}

	def builderClassName(ClassDeclaration cls) {
		cls.qualifiedName + "Builder"
	}

	def builderClass(ClassDeclaration cls, extension TransformationContext ctx) {
		cls.builderClassName.findClass
	}
}
