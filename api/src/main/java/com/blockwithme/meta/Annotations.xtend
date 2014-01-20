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
