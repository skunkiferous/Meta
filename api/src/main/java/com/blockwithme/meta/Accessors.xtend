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

import com.blockwithme.fn1.BooleanFuncObject
import com.blockwithme.fn2.ObjectFuncObjectBoolean
import com.blockwithme.fn1.ByteFuncObject
import com.blockwithme.fn2.ObjectFuncObjectByte
import com.blockwithme.fn1.CharFuncObject
import com.blockwithme.fn2.ObjectFuncObjectChar
import com.blockwithme.fn1.ShortFuncObject
import com.blockwithme.fn2.ObjectFuncObjectShort
import com.blockwithme.fn1.IntFuncObject
import com.blockwithme.fn2.ObjectFuncObjectInt
import com.blockwithme.fn1.FloatFuncObject
import com.blockwithme.fn2.ObjectFuncObjectFloat
import com.blockwithme.fn1.DoubleFuncObject
import com.blockwithme.fn2.ObjectFuncObjectDouble
import com.blockwithme.fn1.LongFuncObject
import com.blockwithme.fn2.ObjectFuncObjectLong
import com.blockwithme.fn1.ObjectFuncObject
import com.blockwithme.fn2.ObjectFuncObjectObject

interface BooleanPropertyAccessor<OWNER_TYPE> extends BooleanFuncObject<OWNER_TYPE>,
ObjectFuncObjectBoolean<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface BytePropertyAccessor<OWNER_TYPE> extends ByteFuncObject<OWNER_TYPE>,
ObjectFuncObjectByte<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface CharPropertyAccessor<OWNER_TYPE> extends CharFuncObject<OWNER_TYPE>,
ObjectFuncObjectChar<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface ShortPropertyAccessor<OWNER_TYPE> extends ShortFuncObject<OWNER_TYPE>,
ObjectFuncObjectShort<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface IntPropertyAccessor<OWNER_TYPE> extends IntFuncObject<OWNER_TYPE>,
ObjectFuncObjectInt<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface FloatPropertyAccessor<OWNER_TYPE> extends FloatFuncObject<OWNER_TYPE>,
ObjectFuncObjectFloat<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface DoublePropertyAccessor<OWNER_TYPE> extends DoubleFuncObject<OWNER_TYPE>,
ObjectFuncObjectDouble<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface LongPropertyAccessor<OWNER_TYPE> extends LongFuncObject<OWNER_TYPE>,
ObjectFuncObjectLong<OWNER_TYPE,OWNER_TYPE> {
	// NOP
}

interface ObjectPropertyAccessor<OWNER_TYPE,PROPERTY_TYPE> extends ObjectFuncObject<PROPERTY_TYPE,OWNER_TYPE>,
		ObjectFuncObjectObject<OWNER_TYPE,OWNER_TYPE,PROPERTY_TYPE> {
	// NOP
}

