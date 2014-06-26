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
package com.blockwithme.meta.demo

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test
import com.blockwithme.util.xtend.annotations.Magic

/**
 * @author monster
 *
 */
class DemoCompileTest {
	 extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(Magic)

	@Test
	def void testCompile() {
		// TODO
//		'''
//		import com.blockwithme.meta.annotations.Bean
//		import com.blockwithme.meta.annotations.Magic
//		@Bean
//		interface DemoType {}
//		interface DemoTypeChild extends DemoType {}
//		@Magic
//		interface Dummy {}
//		'''.compile []
	}
}