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
package com.blockwithme.reprica.skills

import com.blockwithme.meta.beans._Bean
import static extension com.blockwithme.util.xtend.StdExt.*
import java.util.List
import java.util.Set
import java.util.Map
import javax.inject.Provider
import java.util.Random
import java.util.concurrent.atomic.AtomicInteger
import com.blockwithme.util.base.SystemUtils
import java.util.Collections
import com.blockwithme.meta.beans.Ref
import com.blockwithme.meta.beans.annotations.Bean
import com.blockwithme.meta.beans.impl._WitherImpl
import com.blockwithme.meta.HierarchyBuilderFactory
import com.blockwithme.meta.beans.Wither

// TODO Percent modifier on Percent Attribute should add itself, instead of multiplying by itself. But then non-Percent modifier on Percent Attribute should be illegal.
// But if we change this, we need to update the Buff/Debuff/Immunity computation.


/** A Filter specifies if an Effect is going to be taken into account when evaluating a Value. */
interface Filter {
	/** Returns true, if this Effect is going to be taken into account when evaluating a Value. */
	def boolean accept(Effect effect)
	/** Returns a new Filter, combining both Filters. */
	def Filter and(Filter other)
}

/** Base class for Filters. */
abstract class AbstractFilter implements Filter {
	/** Allows combining Filters easily. */
	private static final class AndFilter extends AbstractFilter {
		Filter first
		Filter second
		/** Creates a new Filter instance, combining two existing FIlters. */
		new(Filter first, Filter second) {
			this.first = requireNonNull(first, "first")
			this.second = requireNonNull(second, "second")
		}
		/** {@inheritDoc} */
		override boolean accept(Effect effect) {
			first.accept(effect) && second.accept(effect)
		}
	}

	/** {@inheritDoc} */
	override final Filter and(Filter other) {
		new AndFilter(this, other)
	}
}

/**
 * An effect category groups Effects of the same type together.
 * The buffs/debuffs are stackable if they pertain to different categories.
 *
 * To simply *cancel* an effect, you just need to apply a "0" effect of the
 * same category.
 */
enum EffectCategory {
	/** Simple buff (or debuff) to one, multiple or all stats */
	Simple,
	/** Berserk or negative Berserk increasing or decreasing all stats besides defense/resistance */
	Berserk,
	/**
	 * Bravery or cowardice which increase or decrease attack and the value
	 * increases/decreases per turn until the effect timeouts
	 */
	Bravery,
	/**
	 * Euphoria/virus which increases all stats or decreases them per turn until
	 * the effect timeouts, and where if the euphoria is 50% / 5 turns the 50%
	 * will be reached turn 5 and not turn 1
	 */
	Euphoria
}

/**
 * EffectPolarity represents the "sign" of an Effect; an Effect can either be
 * "positive" (a Buff), "negative" (a Debuff), or "neutral" (an "Immunity")
 */
enum EffectPolarity {
	/** A "positive" Effect */
	Buff,
	/** A "negative" Effect */
	Debuff,
	/**
	 * A "neutral" Effect (there would have been very little use to a "neutral"
	 * Effect that did not also have some other side-effect)
	 */
	Immunity
}

/** Base type of everything in this package */
@Bean
interface Root {
	// NOP
}

/**
 * A Category groups Attributes of the same type together.
 *
 * TODO This should be an enum, but Xtend enums do not support attributes.
 */
@Bean(data=true,instance=true)
interface AttributeCategory {
	public static final class Impl {
		/** Attributes that contribute to "attack" */
		public static val Attack = build(0, "Attack", true, false, false, false, false)
		/** Attributes that contribute to "defense" */
		public static val Defense = build(1, "Defense", false, true, false, false, false)
		/** Attributes that contribute to "crafting" */
		public static val Crafting = build(2, "Crafting", false, false, true, false, false)
		/** Special attributes, are those that normally have a fixed value, and are therefore not displayed */
		public static val Special = build(3, "Special", false, false, false, true, false)
		/** All other attributes */
		public static val Auxiliary = build(4, "Auxiliary", false, false, false, false, true)

		/** All instances of AttributeCategory */
		public static val AttributeCategory[] ALL_SET = #[Attack, Defense, Crafting, Special, Auxiliary]

		public def Object readResolve(AttributeCategory it) {
			return ALL_SET.get(ordinal);
		}

		/** Creates a new AttributeCategory instance */
		private static def AttributeCategory build(int theOrdinal, String theName, boolean theAttack,
			boolean theDefense, boolean theCrafting, boolean theSpecial, boolean theAuxiliary) {
			Meta.ATTRIBUTE_CATEGORY.create.withOrdinalNameAttackDefenseCraftingSpecialAuxiliary(
				theOrdinal, theName, theAttack, theDefense, theCrafting, theSpecial, theAuxiliary)
		}
	}

	/** The ID of this AttributeCategory */
	int ordinal

	/** The name of this AttributeCategory */
	String name

	/** Does this attribute contributes to "attack"? */
	boolean attack

	/** Does this attribute contributes to "defense"? */
	boolean defense

	/** Does this attribute contributes to "crafting"? */
	boolean crafting

	/** Is this a "special" attribute? */
	boolean special

	/** Does this attribute contributes to none of the other categories? */
	boolean auxiliary
}


/** Specifies what (technical) kind of data the attribute contains. */
enum AttributeDataType {
	/** Can be anything */
	Number,
	/** Should normally be between 0 (0%) and 1 (100%) */
	Percent,
	/** Can only be 0 (false), or 1 (true) */
	Boolean,
	/**
	 * The floating point value is cast as a long, which allows storing
	 * *52* bits of data in the value.
	 */
	BitField
}

/** Marker interface, denoting objects that represent meta-information. */
@Bean(sortKeyes=#["qualifiedName"])
interface MetaInfo extends Root {
	class Impl {
		/** Returns the qualified name (parent qualified name + own name) of this meta-info instance */
		static def String getQualifiedName(MetaInfo it) {
			name
		}
	}
	/** All meta-info instance have the name of the code construct that they represent */
	String name
}

/** An Attribute type/descriptor. */
@Bean(instance=true)
interface AttributeType extends MetaInfo, Provider<Attribute> {
	class Impl {
		/** {@inheritDoc} */
		static def String getQualifiedName(AttributeType it) {
			val parent = (it as _Bean).parentBean as EntityType
			if (parent == null) "?."+name else parent.name + "." + name
		}
		/** Pseudo-constructor for attribute types */
		static def void _init_(AttributeType it) {
			min = Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE
			max = Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE
			moreIsBetter = true
		}
		/** Creates a new Attribute */
		static def Attribute get(AttributeType it) {
			val result = Meta.ATTRIBUTE.create
			result.type = new Ref(it)
			result.baseValue = defaultValue
			result
		}
		/**
		 * Is this an "indicator" Attribute?
		 *
		 * Indicator attributes vary constantly, between 0 and the value of another
		 * attribute, pointed to by maxValue. The flag moreIsBetter determines if
		 * it is better to be near 0 or near maxValue.
		 *
		 * What makes this attribute value vary over time is left undefined, as
		 * there are too many possibilities.
		 */
		static def boolean getIndicator(AttributeType it) {
			(maxValue !== null)
		}
	}
	/** The default value of an Attribute of this type. */
	double defaultValue
	/** Allows explicitly clamping the value of an attribute to some minimum */
	double min
	/** Allows explicitly clamping the value of an attribute to some maximum */
	double max
	/** Are bigger values better? That decides if effects are buffs or debuffs. */
	boolean moreIsBetter
	/** Is this attribute a percent/probability (normally between 0.0 and 1.0?), or an "integer value" or a flag/boolean */
	AttributeDataType dataType
	/** The category of the attribute. */
	AttributeCategory category
	/** If this is an "indicator" attribute, then maxValue is the name of the maximum value attribute. */
	// TODO Replace with a "Path"
	String maxValue
	/** If this is an "indicator" attribute, then regenRate is the name of the regeneration rate attribute. */
	// TODO Replace with a "Path"
	String regenRate
}

/** An Attribute is simply a named Value. */
@Bean(instance=true)
interface Attribute extends Root {
	class Impl {
		/** Evaluates the effective value of an attribute of an entity. */
		static def double eval(Attribute it, Filter filter, int turn) {
			var result = baseValue
			for (e : _effects) {
				result = e.eval(filter, result, turn)
			}
			clamp(result,type.value.min,type.value.max)
		}

		/** Describes the evaluation of the effective value of an attribute of an entity. */
		static def String describe(Attribute it, Filter filter, int turn) {
			var result = "baseValue("+baseValue+")"
			for (e : _effects) {
				result = e.describe(filter, result, turn)
			}
			"max(min("+result+","+type.value.max+"),"+type.value.min+")"
		}

		/** Adds one more effect to this attribute. */
		static def void operator_add(Attribute it, Effect newEffect) {
			val type = requireNonNull(requireNonNull(newEffect, "newEffect").type, "newEffect.type")
			val category = requireNonNull(type.category, "newEffect.type.category")
			val cat = type.category
			val effects = _effects
			if (!effects.exists[(cat == category) && immunity]) {
				effects.removeIf[cat == category]
				effects.add(newEffect)
			}
		}

		/** Update this attribute. This will delegate to the effects. */
		static def void update(Attribute it, int turn) {
			_effects.removeIf[expired(turn)]
			_effects.forEach[update(turn)]
		}
		/** If this is an "indicator" attribute, then maxValue is the maximum value attribute. */
		static def Attribute getMaxValue(Attribute it) {
			val maxValue = it.type.value.maxValue;
			if (maxValue === null) null else ((it as _Bean).parentBean as Entity).attr(maxValue)
		}
		/** If this is a "indicator" attribute, then regenRate is the regeneration rate attribute. */
		static def Attribute getRegenRate(Attribute it) {
			val regenRate = it.type.value.regenRate;
			if (regenRate === null) null else ((it as _Bean).parentBean as Entity).attr(regenRate)
		}
	}
	/** The type of the attribute */
	Ref<AttributeType> type
	/** The base value of the attribute */
	double baseValue
	/** All the effects that apply to the base value */
	Effect[] _effects
}

/** A Entity type/descriptor. */
@Bean(instance=true)
interface EntityType extends MetaInfo, Provider<Entity> {
	class Impl {
		/** Creates and adds a new attribute type, with default value, min, max, and non-percent */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category) {
			newAttr(it, name, category, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE, AttributeDataType.Number)
		}
		/** Creates and adds a new non-percent attribute type */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category, double defaultValue, double min, double max) {
			newAttr(it, name, category, defaultValue, min, max, AttributeDataType.Number)
		}
		/** Creates and adds a new attribute type, with default min, and non-percent */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category, double defaultValue, double max) {
			newAttr(it, name, category, defaultValue, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, AttributeDataType.Number)
		}
		/** Creates and adds a new attribute type, with default value, min, and non-percent */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category, double max) {
			newAttr(it, name, category, Skills.DEFAULT_ATTRIBUTE_VALUE, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, AttributeDataType.Number)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, max, and non-percent */
		static def AttributeType newAttr(EntityType it, String name) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE, AttributeDataType.Number)
		}
		/** Creates and adds a new auxiliary non-percent attribute type */
		static def AttributeType newAttr(EntityType it, String name, double defaultValue, double min, double max) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, defaultValue, min, max, AttributeDataType.Number)
		}
		/** Creates and adds a new auxiliary attribute type, with default min, and non-percent */
		static def AttributeType newAttr(EntityType it, String name, double defaultValue, double max) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, defaultValue, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, AttributeDataType.Number)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, and non-percent */
		static def AttributeType newAttr(EntityType it, String name, double max) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, Skills.DEFAULT_ATTRIBUTE_VALUE, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, AttributeDataType.Number)
		}
		/** Creates and adds a new auxiliary attribute type */
		static def AttributeType newAttr(EntityType it, String name, double defaultValue, double min, double max, boolean percent) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, defaultValue, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, AttributeDataType.Number)
		}
		/** Creates and adds a new attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it,
			String name, AttributeCategory category) {
			newAttr(it, name, category, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, AttributeDataType.Percent)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it, String name) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, AttributeDataType.Percent)
		}
		/** Creates and adds a new attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it,
			String name, AttributeCategory category, double defaultValue) {
			newAttr(it, name, category, defaultValue,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, AttributeDataType.Percent)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it, String name, double defaultValue) {
			newAttr(it, name, AttributeCategory.Impl.Auxiliary, defaultValue,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, AttributeDataType.Percent)
		}
		/** Creates and adds a new boolean attribute type */
		static def AttributeType newBooleanAttr(EntityType it, String name, AttributeCategory category) {
			newAttr(it, name, category, 0.0, 0.0, 1.0, AttributeDataType.Boolean)
		}
		/** Creates and adds a new boolean attribute type */
		static def AttributeType newBitFieldAttr(EntityType it, String name, AttributeCategory category) {
			newAttr(it, name, category, 0.0, 0.0, SystemUtils.MAX_DOUBLE_INT_VALUE, AttributeDataType.BitField)
		}
		/** Creates and adds a new attribute type */
		static private def AttributeType newAttr(EntityType it, String name,
			AttributeCategory category, double defaultValue, double min, double max,
			AttributeDataType dataType) {
			if (_attributes.containsKey(name)) {
				throw new IllegalArgumentException("AttributeType "+name+" already exists in "+it.name)
			}
			val result = Meta.ATTRIBUTE_TYPE.create
			result.name = name
			result.category = category
			result.defaultValue = defaultValue
			result.min = min
			result.max = max
			result.dataType = dataType
			_attributes.put(result.name, result)
			result
		}
		/** Returns the attribute type with the given name, if any. */
		static def AttributeType attr(EntityType it,
			String name) {
			_attributes.get(name)
		}
		/** Creates a new Entity */
		static def Entity init(EntityType it, Entity entity) {
			entity._type = new Ref(it)
			for (at : _attributes.values) {
				entity._attributes.put(at.name, at.get)
			}
			entity
		}

		/** Creates a new Entity */
		static def Entity get(EntityType it) {
			init(Meta.ENTITY.create)
		}
		/** Pseudo-constructor for entity types */
		static def void _init_(EntityType it) {
			val simpleName = it.class.simpleName
			name = if (simpleName.endsWith("Impl"))
				simpleName.substring(0, simpleName.length-4)
			else
				simpleName
		}
	}
	/** The types of all the attributes of an entity */
	Map<String,AttributeType> _attributes
}

/**
 * A Entity can have zero or more properties.
 */
interface Entity extends Root {
	class Impl {
		/** Returns the attribute with the given name, if any. */
		static def Attribute attr(Entity it, String name) {
			_attributes.get(name)
		}
		/** Returns the attribute with the given AttributeType, if any. */
		static def Attribute attr(Entity it, AttributeType attributeType) {
			val result = _attributes.get(attributeType.name)
			if ((result != null) && (result.type == attributeType)) result else null
		}
		/** The type of the entity */
		static def EntityType getType(Entity it) {
			_type.value
		}
		/** Lists all the attributes of this entity */
		static def Iterable<Attribute> attrs(Entity it) {
			Collections.unmodifiableCollection(_attributes.values)
		}
		/** Update this Entity. This should delegate to child entities. */
		static def void update(Entity it, int turn) {
			for (a : _attributes.values) {
				a.update(turn)
			}
		}
	}
	/** The type of the entity */
	Ref<EntityType> _type
	/** The attributes of the entity */
	Map<String,Attribute> _attributes
}

/** The type of an effect. */
@Bean(instance=true)
interface EffectType extends EntityType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(EffectType it) {
			newPercentAttr("percentActivation", 1)
			newPercentAttr("percentPerTurn", 1)
			newAttr("duration", Skills.DEFAULT_DURATION_IN_TURN)
			category = EffectCategory.Simple
			_minDuration = Skills.DEFAULT_DURATION_IN_TURN
			_maxDuration = Skills.DEFAULT_DURATION_IN_TURN
		}
		/** Creates a new Effect */
		static def Effect get(EffectType it) {
			val result = init(Meta.EFFECT.create) as Effect
			val range = (_maxDuration - _minDuration)
			result.duration.baseValue = if (range == 0) {
				_maxDuration
			} else {
				var rnd = Skills.RANDOM.nextDouble
				while (rnd === 0) {
					rnd = Skills.RANDOM.nextDouble
				}
				_minDuration + range*rnd
			}
			result.creationTurn = Skills.TURN.get
			result
		}

		/**
		 * Probability of activation, in percent. If the check fails,
		 * the effect will not apply at all.
		 */
		static def AttributeType getPercentActivation(EffectType it) { attr("percentActivation") }

		/** Probability of activation *per turn*, in percent. */
		static def AttributeType getPercentPerTurn(EffectType it) { attr("percentPerTurn") }

		/** Duration of the effect, in turns. */
		static def AttributeType getDuration(EffectType it) { attr("duration") }

		/** Allows specifying a range of duration. */
		static def EffectType durationRange(EffectType it, double min, double max) {
			if (min > max) {
				throw new IllegalArgumentException("min("+min+") > max("+max+")")
			}
			it._minDuration = min
			it._maxDuration = max
			duration.defaultValue = (min + max)/2.0
			it
		}

		/** Returns true, if the attribute matches */
		static def boolean matches(EffectType it, ModifierTarget target, Attribute attribute) {
			true
		}
	}

	/** The category of an effect */
	EffectCategory category

	/** Minimum duration */
	double _minDuration

	/** Maximum duration */
	double _maxDuration
}

/**
 * An effect can modify a value.
 *
 * An effect can *either* be a "buff", a "debuff" or an "immunity".
 */
interface Effect extends Entity {
	class Impl {
		/** Evaluates the effective value of an attribute of an entity. */
		static def double eval(Effect it, Filter filter, double previousValue, int turn) {
			if ((filter == null) || filter.accept(it)) _eval(previousValue, turn) else previousValue
		}

		/** Describes the evaluation of the effective value of an attribute of an entity. */
		static def String describe(Effect it, Filter filter, String previousValue, int turn) {
			if ((filter == null) || filter.accept(it)) _describe(previousValue, turn) else previousValue
		}
		/** The type of the entity */
		static def EffectType getType(Effect it) {
			_type.value as EffectType
		}

		/**
		 * Probability of activation, in percent. If the check fails,
		 * the effect will not apply at all.
		 */
		static def Attribute getPercentActivation(Effect it) { attr("percentActivation") }

		/** Probability of activation *per turn*, in percent. */
		static def Attribute getPercentPerTurn(Effect it) { attr("percentPerTurn") }

		/** Duration of the effect, in turns. */
		static def Attribute getDuration(Effect it) { attr("duration") }

		/** Is this effect expired */
		static def boolean expired(Effect it, int turn) {
			(turn - creationTurn) >= duration.eval(null, turn)
		}

		/** Returns the number of elapsed turns since creation */
		static def int elapsed(Effect it, int turn) {
			(turn - creationTurn)
		}

		/** Returns the "polarity" of an Effect. */
		static def EffectPolarity getPolarity(Effect it) {
			if (buff)
				EffectPolarity.Buff
			else if (debuff)
				EffectPolarity.Debuff
			else
				EffectPolarity.Immunity
		}
	}

	/** The turn on which the effect was created. */
	int creationTurn

	/** Evaluate self, based on the previous value. */
	def double _eval(double previousValue, int turn)
	/** Evaluate self, based on the previous description. */
	def String _describe(String previousValue, int turn)
	/** Returns true if this Effect is "positive" (a buff). */
	def boolean getBuff()
	/** Returns true if this Effect is "negative" (a debuff). */
	def boolean getDebuff()
	/**
	 * Returns true if this Effect is an "immunity" (a zero-effect, that actively
	 * prevent other effects of the same type from replacing it).
	 */
	def boolean getImmunity()
}

/**
 * The type of a "basic" effect.
 */
@Bean(instance=true)
interface BasicEffectType extends EffectType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(BasicEffectType it) {
			// We do not know yet if it's going to be a "percent" effect
			newAttr("strength")
		}
		/** Creates a new BasicEffect */
		static def BasicEffect get(BasicEffectType it) {
			val result = init(Meta.BASIC_EFFECT.create) as BasicEffect
			val range = (_maxEffect - _minEffect)
			result.strength.baseValue = if (range == 0) {
				_maxEffect
			} else {
				var rnd = Skills.RANDOM.nextDouble
				while (rnd === 0) {
					rnd = Skills.RANDOM.nextDouble
				}
				_minEffect + range*rnd
			}
			result
		}

		/** The value/strength of the "effect". */
		static def AttributeType getStrength(BasicEffectType it) { attr("strength") }

		/** Sets the effect range. */
		static def BasicEffectType effectRange(BasicEffectType it, double min, double max) {
			if (min > max) {
				throw new IllegalArgumentException("min("+min+") > max("+max+")")
			}
			it._minEffect = min
			it._maxEffect = max
			strength.defaultValue = (min + max)/2.0
			it
		}

		/** Returns true, if the attribute matches */
		static def boolean matches(BasicEffectType it, ModifierTarget target, Attribute attribute) {
			if (EffectType.Impl.matches(it, target, attribute)) {
				val dataType = attribute.type.value.dataType
				val number = (dataType === AttributeDataType.Number)
				if (percent) ((dataType === AttributeDataType.Percent) || number) else number
			} else {
				false
			}
		}
	}

	/**
	 * Does this effect adds up to the base stat as an absolute value (false)
	 * or instead as a percent (true)?
	 */
	boolean percent

	/** The minimum effect */
	double _minEffect

	/** The maximum effect */
	double _maxEffect
}

/**A basic effect uses a standard algorithm to modify a value */
@Bean(instance=true)
interface BasicEffect extends Effect {
	class Impl {
		/** {@inheritDoc} */
		static def double _eval(BasicEffect it, double previousValue, int turn) {
			val change = strength.eval(null, turn)
			if (type.percent) (previousValue * change) else (previousValue + change)
		}
		/** {@inheritDoc} */
		static def String _describe(BasicEffect it, String previousValue, int turn) {
			val change = strength.eval(null, turn)
			previousValue + " + "+type.name+"("+if (type.percent)
				(change*100.0)+"%)"
			else
				change+")"
		}
		/** Returns true if this Effect is "positive" (a buff). */
		static def boolean getBuff(BasicEffect it) {
			var result = if (type.percent) (strength.baseValue > 1) else (strength.baseValue > 0)
			if (strength.type.value.moreIsBetter) result else !result
		}
		/** Returns true if this Effect is "negative" (a debuff). */
		static def boolean getDebuff(BasicEffect it) {
			var result = if (type.percent) (strength.baseValue < 1) else (strength.baseValue < 0)
			if (strength.type.value.moreIsBetter) result else !result
		}
		/**
		 * Returns true if this Effect is an "immunity" (a zero-effect, that actively
		 * prevent other effects of the same type from replacing it).
		 */
		static def boolean getImmunity(BasicEffect it) {
			// "neutral" stays neutral, independent of "moreIsBetter"
			if (type.percent) (strength.baseValue === 1) else (strength.baseValue === 0)
		}
		/** The type of the entity */
		static def BasicEffectType getType(BasicEffect it) {
			_type.value as BasicEffectType
		}
		/** The value/strength of the "effect". */
		static def Attribute getStrength(BasicEffect it) { attr("strength") }
	}
}

/**
 * The type of a "death" effect.
 */
@Bean(instance=true)
interface DeathEffectType extends EffectType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(DeathEffectType it) {
		}
		/** Creates a new BasicEffect */
		static def DeathEffect get(DeathEffectType it) {
			init(Meta.DEATH_EFFECT.create) as DeathEffect
		}

		/** Returns true, if the attribute matches */
		static def boolean matches(DeathEffectType it, ModifierTarget target, Attribute attribute) {
			if (EffectType.Impl.matches(it, target, attribute)) {
				val at = attribute.type.value;
				// TODO Update matching to something more reliable
				(at.dataType === AttributeDataType.Boolean) && (at.name == "dead")
			} else {
				false
			}
		}
	}
}

/** A "death" effect */
@Bean(instance=true)
interface DeathEffect extends Effect {
	class Impl {
		/** {@inheritDoc} */
		static def double _eval(DeathEffect it, double previousValue, int turn) {
			1
		}
		/** {@inheritDoc} */
		static def String _describe(DeathEffect it, String previousValue, int turn) {
			"1"
		}
		/** Returns true if this Effect is "positive" (a buff). */
		static def boolean getBuff(DeathEffect it) {
			false
		}
		/** Returns true if this Effect is "negative" (a debuff). */
		static def boolean getDebuff(DeathEffect it) {
			true
		}
		/**
		 * Returns true if this Effect is an "immunity" (a zero-effect, that actively
		 * prevent other effects of the same type from replacing it).
		 */
		static def boolean getImmunity(DeathEffect it) {
			false
		}
		/** The type of the entity */
		static def DeathEffectType getType(DeathEffect it) {
			_type.value as DeathEffectType
		}
	}
}

/** Matches an attribute, to which an effect should be applied */
@Bean(data=true)
interface AttributeMatcher {
	/** Returns true, if the attribute matches */
	def boolean matches(ModifierTarget target, Attribute attribute)
}

/** Simply matches an attribute name */
@Bean(data=true,instance=true)
interface SimpleAttributeMatcher extends AttributeMatcher {
	class Impl {
		/** Constructor */
		static def SimpleAttributeMatcher create(String name) {
			Meta.SIMPLE_ATTRIBUTE_MATCHER.create.withName(requireNonNull(name, "name"))
		}
		/** Returns true, if the attribute matches */
		static def boolean matches(SimpleAttributeMatcher it, ModifierTarget target, Attribute attribute) {
			attribute.type.value.name == name
		}
	}
	/** The desired name */
	String name
}

/** A pair of attribute matcher, and effect type, to create an effect, when appropriate */
@Bean(data=true,instance=true)
interface EffectBuilder {
	class Impl {
		static def create(EffectType type, AttributeMatcher matcher) {
			if (!requireNonNull(type, "type").immutable) {
				throw new IllegalStateException("type must be immutable!")
			}
			Meta.EFFECT_BUILDER.create.withTypeMatcher(type, matcher)
		}
		/** Returns true, if the attribute matches */
		static def boolean matches(EffectBuilder it, ModifierTarget target, Attribute attribute) {
			type.matches(target, attribute) && matcher.matches(target, attribute)
		}
	}
	EffectType type
	AttributeMatcher matcher
}

/** The type of a modifier. */
@Bean(instance=true)
interface ModifierType extends EntityType {
	class Impl {
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, effect, effect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, false, SimpleAttributeMatcher.Impl.create(attributeName))
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, false, matcher)
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, minEffect, maxEffect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, minEffect, maxEffect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, effect, effect, false, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, false, matcher)
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, effect, effect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			String attributeName) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, true, SimpleAttributeMatcher.Impl.create(attributeName))
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect2(ModifierType it, double percentActivation,
			double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				EffectCategory.Simple, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentSimpleEffect(ModifierType it, double percentActivation,
			double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				EffectCategory.Simple, minEffect, maxEffect, true, matcher)
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, duration, duration,
				category, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, 1.0, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double duration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, duration, duration,
				category, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double effect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, effect, effect, true, matcher)
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newPercentEffect(ModifierType it, double percentActivation,
			EffectCategory category, double minDuration, double maxDuration,
			String name, double minEffect, double maxEffect,
			AttributeMatcher matcher) {
			newEffect(it, percentActivation, 1.0, name, minDuration, maxDuration,
				category, minEffect, maxEffect, true, matcher)
		}
		/** Creates and adds a new DeathEffect builder */
		static def EffectBuilder newDeathEffect(ModifierType it, double percentPerTurn,
			double minDuration, double maxDuration) {
			val type = Meta.DEATH_EFFECT_TYPE.create
			type.percentActivation.defaultValue = 1
			type.percentPerTurn.defaultValue = percentPerTurn
			type.durationRange(minDuration, maxDuration)
			type.category = EffectCategory.Simple
			type.name = "Death"
			val result = EffectBuilder.Impl.create(type.snapshot, SimpleAttributeMatcher.Impl.create("dead"))
			_builders.add(result)
			result
		}

		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newEffect(ModifierType it, double percentActivation,
			double percentPerTurn, String name, double minDuration, double maxDuration,
			EffectCategory category, double minEffect, double maxEffect,
			boolean percent, AttributeMatcher matcher) {
			requireNonNull(matcher, "matcher")
			val type = Meta.BASIC_EFFECT_TYPE.create
			type.percentActivation.defaultValue = percentActivation
			type.percentPerTurn.defaultValue = percentPerTurn
			type.durationRange(minDuration, maxDuration)
			type.effectRange(minEffect, maxEffect)
			type.percent = percent
			type.category = category
			type.name = name
			val result = EffectBuilder.Impl.create(type.snapshot, matcher)
			_builders.add(result)
			result
		}
		/** Creates a new Modifier */
		static def Modifier get(ModifierType it) {
			init(Meta.MODIFIER.create) as Modifier
		}
	}
	/** All the effect builders */
	EffectBuilder[] _builders
	/** The type of entity to which this modifier can apply */
	Class _targetEntity
	/** Is this Modifier a "skill"? */
	boolean skill
}

/** A modifier is an effect factory, representing the effects of one attack/skill/equipment/... */
interface Modifier extends Entity {
	class Impl {
		/** The type of the entity */
		static def ModifierType getType(Modifier it) {
			_type.value as ModifierType
		}
		/** Applies a modifier to an entity. Returns true on success. */
		static def boolean apply(Modifier it, ModifierTarget target, int turn) {
			var result = false
			val targetEntity = type._targetEntity
			if ((targetEntity == null) || SystemUtils.isAssignableFrom(targetEntity, target.class)) {
				val attrs = target.attrs
				val rnd = Skills.RANDOM
				if (cause.canApply(it, turn, rnd) && target.canReceive(it, turn, rnd)) {
					for (b : type._builders) {
						for (a : attrs) {
							if (b.matches(target, a)
								&& (rnd.nextDouble < b.type.percentActivation.defaultValue)) {
								val effect = b.type.get
								if (cause.canApply(effect, turn, rnd)
									&& target.canReceive(effect, turn, rnd)) {
									a += effect
									result = true
								}
							}
						}
					}
				}
			}
			result
		}
	}

	/** The cause of a Modifier */
	ModifierCause cause
}

/** The type of a Drunk modifier. */
@Bean(instance=true)
interface DrunkType extends ModifierType {
	class Impl {
		/** Pseudo-constructor for modifier types */
		static def void _init_(DrunkType it) {
			newSimpleEffect(5, "strength", 5, "strength")
			newPercentSimpleEffect(5, "dexterity", 0.5, "dexterity")
		}
		/** Creates a new Drunk Modifier */
		static def Drunk get(DrunkType it, ModifierCause drinker) {
			val result = init(Meta.DRUNK.create) as Drunk
			result.cause = drinker
			result
		}
	}
}

/** A Drunk modifier */
@Bean(instance=true)
interface Drunk extends Modifier {
	class Impl {
		/** The type of the entity */
		static def DrunkType getType(Drunk it) {
			_type.value as DrunkType
		}
	}
}

/**
 * The type of a character.
 *
 * Growth rate on gaining level that is more then 100% means that the growth is:
 *     growth/100 + current*rnd(growth%100)
 */
@Bean(instance=true)
interface CharacterType extends EntityType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(CharacterType it) {
			newAttr("speed", AttributeCategory.Impl.Attack).moreIsBetter = false
			newAttr("strength", AttributeCategory.Impl.Attack)
			newAttr("anima", AttributeCategory.Impl.Attack)

			newPercentAttr("dexterity", AttributeCategory.Impl.Attack)
			newPercentAttr("rage", AttributeCategory.Impl.Attack)
			newPercentAttr("fury", AttributeCategory.Impl.Attack)

			newPercentAttr("psyche", AttributeCategory.Impl.Defense)
			newPercentAttr("defense", AttributeCategory.Impl.Defense)
			newPercentAttr("reflex", AttributeCategory.Impl.Defense)
			newPercentAttr("block", AttributeCategory.Impl.Defense)
			newPercentAttr("constitution", AttributeCategory.Impl.Defense)
			newPercentAttr("spirit", AttributeCategory.Impl.Defense)
			newPercentAttr("harmony", AttributeCategory.Impl.Defense)

			newAttr("intelligence", AttributeCategory.Impl.Crafting)
			newAttr("artistry", AttributeCategory.Impl.Crafting)

			newPercentAttr("visibleToFriends", AttributeCategory.Impl.Special).defaultValue = 1.0
			newPercentAttr("visibleToFoes", AttributeCategory.Impl.Special).defaultValue = 1.0
			newPercentAttr("confused", AttributeCategory.Impl.Special).moreIsBetter = false
			newPercentAttr("skilled", AttributeCategory.Impl.Special).defaultValue = 1.0
			newPercentAttr("paralyzed", AttributeCategory.Impl.Special).moreIsBetter = false
			newBooleanAttr("dead", AttributeCategory.Impl.Special).moreIsBetter = false
			newPercentAttr("xpGainRate", AttributeCategory.Impl.Special).defaultValue = 1.0
			newPercentAttr("moneyGainRate", AttributeCategory.Impl.Special).defaultValue = 1.0
			newPercentAttr("lootGainRate", AttributeCategory.Impl.Special).defaultValue = 1.0
			newPercentAttr("hpRegeneration", AttributeCategory.Impl.Special)
			newPercentAttr("manaRegeneration", AttributeCategory.Impl.Special)

			newAttr("maxMana")
			val mana = newAttr("mana")
			mana.maxValue = "maxMana"
			mana.regenRate = "manaRegeneration"
			newAttr("maxHp")
			val hp = newAttr("hp")
			hp.maxValue = "maxHp"
			hp.regenRate = "hpRegeneration"
			newAttr("level")
			newAttr("xp")
			newAttr("money")
		}
		/** Creates a new Character */
		static def Character get(CharacterType it) {
			init(Meta.CHARACTER.create) as Character
		}
	}
}

/**
 * The "cause" of a Modifier.
 *
 * All modifiers need to have a cause.
 */
interface ModifierCause extends Entity {
	class Impl {
		/** Returns true, if this Modifier cause is currently able to apply the given Modifier */
		static def boolean canApply(ModifierCause it, Modifier mod, int turn, Random rnd) {
			true
		}
		/** Returns true, if this Modifier cause is currently able to apply the given Effect */
		static def boolean canApply(ModifierCause it, Effect effect, int turn, Random rnd) {
			true
		}
	}
}

/**
 * The "target" of a Modifier.
 */
interface ModifierTarget extends Entity {
	class Impl {
		/** Returns true, if this Modifier target is currently able to receive the given Modifier */
		static def boolean canReceive(ModifierTarget it, Modifier mod, int turn, Random rnd) {
			!modifierImmunities.exists[value == mod.type]
		}
		/** Returns true, if this Modifier target is currently able to receive the given Effect */
		static def boolean canReceive(ModifierTarget it, Effect effect, int turn, Random rnd) {
			!effectImmunities.exists[value == effect.type]
		}
	}

	/** List of immunities to Modifiers */
	Ref<ModifierType>[] modifierImmunities

	/** List of immunities to Effects */
	Ref<EffectType>[] effectImmunities
}


/** Represents a Player character, so we have something to test against */
@Bean(instance=true)
interface Character extends ModifierCause, ModifierTarget {
	class Impl {
		/** The type of the entity */
		static def CharacterType getType(Character it) {
			_type.value as CharacterType
		}
		/** Returns true, if this Modifier cause is currently able to apply the given Modifier */
		static def boolean canApply(Character it, Modifier mod, int turn, Random rnd) {
			var result = true
			if (mod.type.skill) {
				val skilled = skilled.eval(null, turn)
				if ((skilled != 1) && (rnd.nextDouble > skilled)) {
					result = false
				}
			}
			val paralyzed = paralyzed.eval(null, turn)
			if ((paralyzed > 0) && (rnd.nextDouble < paralyzed)) {
				result = false
			}
			result
		}

		/** The attack rate. */
		static def Attribute speed(Character it) { attr("speed") }
		/** The current spellpower. */
		static def Attribute mana(Character it) { attr("mana") }
		/** The maximum spellpower. */
		static def Attribute maxMana(Character it) { attr("maxMana") }
		/** The current Hitpoints (life) */
		static def Attribute hp(Character it) { attr("hp") }
		/** The maximum Hitpoints (life) */
		static def Attribute maxHp(Character it) { attr("maxHp") }
		/** Affects your ability to enchant items OR craft magical items such as potions or even scrolls */
		static def Attribute intelligence(Character it) { attr("intelligence") }
		/** Resistance to incoming magical attacks and mana growth */
		static def Attribute psyche(Character it) { attr("psyche") }
		/** Affects your ability to craft */
		static def Attribute artistry(Character it) { attr("artistry") }
		/** Resistance to incoming physical attacks and hp growth */
		static def Attribute defense(Character it) { attr("defense") }
		/** Chance to dodge incoming attacks */
		static def Attribute reflex(Character it) { attr("reflex") }
		/** Chance to block incoming attacks */
		static def Attribute block(Character it) { attr("block") }
		/** Chance to hit the opponent */
		static def Attribute dexterity(Character it) { attr("dexterity") }
		/** Chance to cause a critical hit */
		static def Attribute rage(Character it) { attr("rage") }
		/** % increase on critical hits. */
		static def Attribute fury(Character it) { attr("fury") }
		/** Resistance to poison and debuffs that affect damage taken */
		static def Attribute constitution(Character it) { attr("constitution") }
		/** Resistance to lifedrain and debuffs affecting your attack stats */
		static def Attribute spirit(Character it) { attr("spirit") }
		/** Affects the power of physical attacks */
		static def Attribute strength(Character it) { attr("strength") }
		/** Affects the power of magical attacks */
		static def Attribute anima(Character it) { attr("anima") }
		/** "the opposite of rage" : reduces chance to receive a critical hit from enemy */
		static def Attribute harmony(Character it) { attr("harmony") }
		/** The level (general power) of the character */
		static def Attribute level(Character it) { attr("level") }
		/** The earned experience points since starting the current level */
		static def Attribute xp(Character it) { attr("xp") }
		/** The percentage of "visible" exposed to Friends. */
		static def Attribute visibleToFriends(Character it) { attr("visibleToFriends") }
		/** The percentage of "visible" exposed to Foes. */
		static def Attribute visibleToFoes(Character it) { attr("visibleToFoes") }
		/** The percentage/amount of confusion. */
		static def Attribute confused(Character it) { attr("confused") }
		/** The rate at which XPs are gained (compared to the normal rate). */
		static def Attribute xpGainRate(Character it) { attr("xpGainRate") }
		/** The rate at which money is looted (compared to the normal rate). */
		static def Attribute moneyGainRate(Character it) { attr("moneyGainRate") }
		/** The rate at which objects are looted (compared to the normal rate). */
		static def Attribute lootGainRate(Character it) { attr("lootGainRate") }
		/** The rate at which hit-points are regenerated (compared to the normal rate). */
		static def Attribute hpRegeneration(Character it) { attr("hpRegeneration") }
		/** The rate at which mana is regenerated (compared to the normal rate). */
		static def Attribute manaRegeneration(Character it) { attr("manaRegeneration") }
		/** Is this Character able to use skills, as a probability? */
		static def Attribute skilled(Character it) { attr("skilled") }
		/** Is this Character paralyzed (unable to do anything), as a probability? */
		static def Attribute paralyzed(Character it) { attr("paralyzed") }
		/** Is the character "dead" (through a "Death" effect)? */
		static def Attribute dead(Character it) { attr("dead") }
	}

	/** The player name */
	String name
}

/** A System of Entity; all EntityTypes must be defined here. */
@Bean(instance=true)
interface EntitySystem extends MetaInfo {
	class Impl {
		/** Adds a new entity type to the system. */
		static def EntityType add(EntitySystem it, EntityType entityType) {
			val name = requireNonNull(entityType,  "entityType").name
			requireNonNull(name,  "entityType.name")
			if (_entityTypes.containsKey(name)) {
				throw new IllegalArgumentException("EntityType "+name+" already exists")
			}
			if (!entityType.immutable) {
				throw new IllegalArgumentException("EntityType "+name+" must be immutable")
			}
			_entityTypes.put(name, entityType)
			entityType
		}

		/** Lists all the entity types */
		static def Iterable<EntityType> list(EntitySystem it) {
			_entityTypes.values
		}

		/** Returns the entity type with the given name, or null. */
		static def EntityType find(EntitySystem it, String name) {
			_entityTypes.get(name)
		}
	}

	/** All the entity types in the system. */
	Map<String,EntityType> _entityTypes
}

interface Skills {
	/** A source of randomness. */
	Random RANDOM = new Random

	/**
	 * The current game turn.
	 * TODO This is just a hack; the turn should be "per map"
	 */
	AtomicInteger TURN = new AtomicInteger

	/** The entity system singleton */
	EntitySystem ENTITY_SYSTEM = Meta.ENTITY_SYSTEM.create

	/** The EffectType singleton */
	EffectType EFFECT_TYPE = ENTITY_SYSTEM.add(Meta.EFFECT_TYPE.create.snapshot) as EffectType

	/** The CharacterType singleton */
	CharacterType CHARACTER_TYPE = ENTITY_SYSTEM.add(Meta.CHARACTER_TYPE.create.snapshot) as CharacterType

	/** The DrunkType singleton */
	DrunkType DRUNK_TYPE = ENTITY_SYSTEM.add(Meta.DRUNK_TYPE.create.snapshot) as DrunkType

	/** The default attribute value */
	double DEFAULT_ATTRIBUTE_VALUE = 0.0

	/** The default minimum attribute value */
	double DEFAULT_MINIMUM_ATTRIBUTE_VALUE = 0.0

	/** The default maximum attribute value */
	double DEFAULT_MAXIMUM_ATTRIBUTE_VALUE = 99_999.0

	/** The default maximum "percent" attribute value */
	double DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE = 100.0

	/** The default probability of activation */
	double DEFAULT_PROBABILITY_OF_ACTIVATION = 1.0

	/** The default probability per turn */
	double DEFAULT_PROBABILITY_PER_TURN = 1.0

	/** The default duration in turn */
	double DEFAULT_DURATION_IN_TURN = 999.0

	/** Absolute maximum for "integer" attributes */
	double MAX_DOUBLE_INT_VALUE = SystemUtils.MAX_DOUBLE_INT_VALUE

	/** Absolute minimum for "integer" attributes */
	double MIN_DOUBLE_INT_VALUE = SystemUtils.MIN_DOUBLE_INT_VALUE
}
