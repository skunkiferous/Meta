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
package test.com.blockwithme.meta

import com.blockwithme.meta.Hierarchy

/**
 * @author monster
 *
 */
class MyLazyLoadListenerTST {
        public static val TST = Hierarchy.postCreateMetaProperty(
        	com.blockwithme.meta.Meta.BUILDER.newMetaProperty(com.blockwithme.meta.Meta.TYPE, "tst", Boolean, false)
        )
}