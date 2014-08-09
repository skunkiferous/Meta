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

import com.blockwithme.meta.annotations.Bean
import com.blockwithme.meta.beans._Bean
import java.util.List
import java.util.Set
import java.util.Map
import static java.util.Objects.*

/** A Filter specifies if an Effect is going to be taken into account when evaluating a Value. */
interface Filter {
	/** Returns true, if this Effect is going to be taken into account when evaluating a Value. */
	def boolean accept(Effect effect)
	/** Returns a new Filter, combining both Filters. */
	def Filter and(Filter other)
}

/** Base class for Filters. */
abstract class AbstractFilter implements Filter {
	/** Allows combining FIlters easily. */
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
 * The buffs debuffs are stackable if they pertain to different categories.
 */
enum EffectCategory {
	/** Simple buff to one, multiple or all stats (or debuffs) */
	Simple,
	/** Berserk or negative Berserk increasing or decreasing all stats besides def/res */
	Berserk,
	/**
	 * Bravery or cowardice which increase or decrease att and the value
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

/** A Category groups Attributes of the same type together. */
enum AttributeCategory {
	/** Attributes that contribute to "attack" */
	Attack,
	/** Attributes that contribute to "defense" */
	Defense,
	/** All other attributes */
	Auxiliary
}

/** Base type of everything in this package */
@Bean
interface Root {
	// NOP
}

/** Marker interface, denoting objects that represent meta-information. */
@Bean(sortKeyes=#["name"])
interface MetaInfo extends Root {
	class Impl {
		// TODO This should be a virtual property
		/** Returns the qualified name (parent qualified name + own name) of this meta-info instance */
		static def String qualifiedName(EntityType it) {
			name
		}
	}
	/** All meta-info instance have the name of the code construct that they represent */
	String name
}

/** An Attribute type/descriptor. */
@Bean(instance=true)
interface AttributeType extends MetaInfo {
	class Impl {
		// TODO This should be a virtual property
		/** {@inheritDoc} */
		static def String qualifiedName(AttributeType it) {
			val parent = (it as _Bean).parent as EntityType
			if (parent == null) "?."+name else parent.name + "." + name
		}
		/** Pseudo-constructor for attribute types */
		static def void _init_(AttributeType it) {
			min = Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE
			max = Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE
			moreIsBetter = true
		}
	}
	/** Allows explicitly clamping the value of an attribute to some minimum */
	double min
	/** Allows explicitly clamping the value of an attribute to some maximum */
	double max
	/** Are bigger values better? That decided if effects are buffs or debuffs. */
	boolean moreIsBetter
	/** The category of the attribute. */
	AttributeCategory category
}

/** A Entity type/descriptor. */
@Bean(instance=true)
interface EntityType extends MetaInfo {
	/** The types of all the attributes of an entity */
	Map<String,AttributeType> attributes
}

/** A System of Entity; all EntityTypes must be defined here. */
@Bean(instance=true)
interface EntitySystem extends MetaInfo {
	class Impl {
		/** Adds a new entity type to the system. */
		static def void add(EntitySystem it, EntityType entityType) {
			val name = requireNonNull(entityType,  "entityType").name
			requireNonNull(name,  "entityType.name")
			if (_entityTypes.containsKey(name)) {
				throw new IllegalArgumentException("EntityType "+name+" already exists")
			}
			if (!entityType.immutable) {
				throw new IllegalArgumentException("EntityType "+name+" must be immutable")
			}
			_entityTypes.put(name, entityType)
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

/** An Attribute is simply a named Value. */
@Bean(instance=true)
interface Attribute extends Root {
	class Impl {
		/** Evaluates the effective value of an attribute of an entity. */
		static def double eval(Attribute it, Filter filter) {
			var result = baseValue
			for (e : _effects) {
				result = e.eval(filter, result)
			}
			val min = type.min
			val max = type.max
			if (result < min) {
				result = min
			}
			if (result > max) {
				result = max
			}
			result
		}

		/** Describes the evaluation of the effective value of an attribute of an entity. */
		static def String describe(Attribute it, Filter filter) {
			var result = "baseValue("+baseValue+")"
			for (e : _effects) {
				result = e.describe(filter, result)
			}
			val min = type.min
			val max = type.max
			if (min != Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE) {
				result = "min("+result+","+min+")"
			}
			if (max != Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE) {
				result = "max("+result+","+max+")"
			}
			result
		}

		/** Adds one more effect to this attribute. */
		static def void addEffect(Attribute it, Effect newEffect) {
			val category = requireNonNull(requireNonNull(newEffect, "newEffect").category, "newEffect.category")
			val iter = _effects.iterator
			while (iter.hasNext) {
				val next = iter.next
				if (next.category == category) {
					iter.remove
				}
			}
			_effects.add(newEffect)
		}
	}
	/** The type of the attribute */
	AttributeType type
	/** The base value of the attribute */
	double baseValue
	/** All the effects that apply to the base value */
	Effect[] _effects
}

/** A Entity can have zero or more properties. */
interface Entity extends Root {
	class Impl {
		/** Creates a new attribute type */
		protected static def AttributeType attrType(EntityType type,
			String name, AttributeCategory category) {
			val result = Meta.ATTRIBUTE_TYPE.create
			result.name = name
			result.category = category
			type.attributes.put(result.name, result)
			result
		}

		/** Creates a new attribute */
		protected static def Attribute attr(AttributeType attributeType) {
			val result = Meta.ATTRIBUTE.create
			result.type = attributeType
			result
		}
	}
	/** The type of the entity */
	EntityType type
	/** The attributes of the entity */
	Attribute[] attributes
}

/** An effect can modify a value */
interface Effect extends Entity {
	class Impl extends Entity.Impl {
		/** Cached entity type for Effect */
		static var EntityType typeCache
		/** Cached attribute type for "activationProbability" */
		static var AttributeType activationProbabilityCache
		/** Cached attribute type for "perTurnProbability" */
		static var AttributeType perTurnProbabilityCache
		/** Cached attribute type for "duration" */
		static var AttributeType durationCache
		/** Pseudo-constructor for basic effects */
		static def void _init_(Effect it) {
			if (typeCache == null) {
				val type = Meta.ENTITY_TYPE.create
				type.name = Effect.name

				val activationProbability = attrType(type, "activationProbability", AttributeCategory.Auxiliary)
				val perTurnProbability = attrType(type, "perTurnProbability", AttributeCategory.Auxiliary)
				val duration = attrType(type, "duration", AttributeCategory.Auxiliary)

				typeCache = type.snapshot

				activationProbabilityCache = typeCache.attributes.get(activationProbability.name)
				perTurnProbabilityCache = typeCache.attributes.get(perTurnProbability.name)
				durationCache = typeCache.attributes.get(duration.name)

				Skills.SYSTEM.add(typeCache)
			}
			type = typeCache

			activationProbability = attr(activationProbabilityCache)
			activationProbability.baseValue = Skills.DEFAULT_PROBABILITY_OF_ACTIVATION

			perTurnProbability = attr(perTurnProbabilityCache)
			perTurnProbability.baseValue = Skills.DEFAULT_PROBABILITY_PER_TURN

			duration = attr(durationCache)
			duration.baseValue = Skills.DEFAULT_DURATION_IN_TURN
		}
		/** Evaluates the effective value of an attribute of an entity. */
		static def double eval(Effect it, Filter filter, double previousValue) {
			if ((filter == null) || filter.accept(it)) _eval(previousValue) else previousValue
		}

		/** Describes the evaluation of the effective value of an attribute of an entity. */
		static def String describe(Effect it, Filter filter, String previousValue) {
			if ((filter == null) || filter.accept(it)) _describe(previousValue) else previousValue
		}
		/** Returns true if this Effect is "negative" (a debuff). */
		static def boolean debuff(Effect it) {
			!buff
		}
	}

	/** The category of an effect */
	EffectCategory category

	/**
	 * Does this effect adds up to the base stat as an absolute value (false)
	 * or instead as a percent (true)?
	 */
	boolean percent

	/** The turn on which the effect was created. */
	int creationTurn

	/**
	 * Probability of activation, in percent. If the check fails,
	 * the effect will not apply at all.
	 */
	Attribute activationProbability

	/** Probability of activation *per turn*, in percent. */
	Attribute perTurnProbability

	/** Duration of the effect, in turns. */
	Attribute duration

	/** Evaluate self, based on the previous value. */
	def double _eval(double previousValue)
	/** Evaluate self, based on the previous description. */
	def String _describe(String previousValue)
	/** Returns true if this Effect is "positive" (a buff). */
	def boolean buff()
}

/** A basic effect uses a standard algorithm to modify a value */
@Bean(instance=true)
interface BasicEffect extends Effect {
	class Impl extends Entity.Impl {
		/** Cached entity type for BasicEffect */
		static var EntityType typeCache
		/** Cached attribute type for "effect" */
		static var AttributeType effectCache
		/** Pseudo-constructor for basic effects */
		static def void _init_(BasicEffect it) {
			if (typeCache == null) {
				val type = Meta.ENTITY_TYPE.create
				type.name = BasicEffect.name

				val effect =  attrType(type, "effect", AttributeCategory.Auxiliary)

				typeCache = type.snapshot

				effectCache = typeCache.attributes.get(effect.name)

				Skills.SYSTEM.add(typeCache)
			}
			type = typeCache

			effect = attr(effectCache)
		}
		/** {@inheritDoc} */
		static def double _eval(BasicEffect it, double previousValue) {
			val change = effect.eval(null)
			if (percent) (previousValue * change) else (previousValue + change)
		}
		/** {@inheritDoc} */
		static def String _describe(BasicEffect it, String previousValue) {
			val change = effect.eval(null)
			previousValue + " + "+type.name+"("+if (percent)
				(change*100.0)+"%)"
			else
				change+")"
		}
		/** Returns true if this Effect is "positive" (a buff). */
		static def boolean buff(BasicEffect it) {
			effect.baseValue > 0
		}
	}
	/** The value/strength of the "effect". */
	Attribute effect
}

/** Represents a Player character, so we have something to test against */
@Bean(instance=true)
interface Character extends Entity {
	class Impl extends Entity.Impl {
		/** Cached entity type for Player */
		static var EntityType typeCache

		/** Cached attribute type for "speed" */
		static var AttributeType speedCache
		/** Cached attribute type for "dexterity" */
		static var AttributeType dexterityCache
		/** Cached attribute type for "strength" */
		static var AttributeType strengthCache
		/** Cached attribute type for "anima" */
		static var AttributeType animaCache
		/** Cached attribute type for "rage" */
		static var AttributeType rageCache
		/** Cached attribute type for "fury" */
		static var AttributeType furyCache

		/** Cached attribute type for "psyche" */
		static var AttributeType psycheCache
		/** Cached attribute type for "defense" */
		static var AttributeType defenseCache
		/** Cached attribute type for "reflex" */
		static var AttributeType reflexCache
		/** Cached attribute type for "block" */
		static var AttributeType blockCache
		/** Cached attribute type for "constitution" */
		static var AttributeType constitutionCache
		/** Cached attribute type for "spirit" */
		static var AttributeType spiritCache
		/** Cached attribute type for "harmony" */
		static var AttributeType harmonyCache

		/** Cached attribute type for "mana" */
		static var AttributeType manaCache
		/** Cached attribute type for "hp" */
		static var AttributeType hpCache
		/** Cached attribute type for "intelligence" */
		static var AttributeType intelligenceCache
		/** Cached attribute type for "artistry" */
		static var AttributeType artistryCache
		/** Cached attribute type for "level" */
		static var AttributeType levelCache

		/** Pseudo-constructor for basic effects */
		static def void _init_(Character it) {
			if (typeCache == null) {
				val type = Meta.ENTITY_TYPE.create
				type.name = Character.name

				val speed = attrType(type, "speed", AttributeCategory.Attack)
				val dexterity = attrType(type, "dexterity", AttributeCategory.Attack)
				val rage = attrType(type, "rage", AttributeCategory.Attack)
				val fury = attrType(type, "fury", AttributeCategory.Attack)
				val strength = attrType(type, "strength", AttributeCategory.Attack)
				val anima = attrType(type, "anima", AttributeCategory.Attack)

				val psyche = attrType(type, "psyche", AttributeCategory.Defense)
				val defense = attrType(type, "defense", AttributeCategory.Defense)
				val reflex = attrType(type, "reflex", AttributeCategory.Defense)
				val block = attrType(type, "block", AttributeCategory.Defense)
				val constitution = attrType(type, "constitution", AttributeCategory.Defense)
				val spirit = attrType(type, "spirit", AttributeCategory.Defense)
				val harmony = attrType(type, "harmony", AttributeCategory.Defense)

				val mana = attrType(type, "mana", AttributeCategory.Auxiliary)
				val hp = attrType(type, "hp", AttributeCategory.Auxiliary)
				val intelligence = attrType(type, "intelligence", AttributeCategory.Auxiliary)
				val artistry = attrType(type, "artistry", AttributeCategory.Auxiliary)
				val level = attrType(type, "level", AttributeCategory.Auxiliary)

				typeCache = type.snapshot

				speedCache = typeCache.attributes.get(speed.name)
				manaCache = typeCache.attributes.get(mana.name)
				hpCache = typeCache.attributes.get(hp.name)
				intelligenceCache = typeCache.attributes.get(intelligence.name)
				psycheCache = typeCache.attributes.get(psyche.name)
				artistryCache = typeCache.attributes.get(artistry.name)
				defenseCache = typeCache.attributes.get(defense.name)
				reflexCache = typeCache.attributes.get(reflex.name)
				blockCache = typeCache.attributes.get(block.name)
				dexterityCache = typeCache.attributes.get(dexterity.name)
				rageCache = typeCache.attributes.get(rage.name)
				furyCache = typeCache.attributes.get(fury.name)
				constitutionCache = typeCache.attributes.get(constitution.name)
				spiritCache = typeCache.attributes.get(spirit.name)
				strengthCache = typeCache.attributes.get(strength.name)
				animaCache = typeCache.attributes.get(anima.name)
				harmonyCache = typeCache.attributes.get(harmony.name)
				levelCache = typeCache.attributes.get(level.name)

				Skills.SYSTEM.add(typeCache)
			}
			type = typeCache

			speed = attr(speedCache)
			mana = attr(manaCache)
			hp = attr(hpCache)
			intelligence = attr(intelligenceCache)
			psyche = attr(psycheCache)
			artistry = attr(artistryCache)
			defense = attr(defenseCache)
			reflex = attr(reflexCache)
			block = attr(blockCache)
			dexterity = attr(dexterityCache)
			rage = attr(rageCache)
			fury = attr(furyCache)
			constitution = attr(constitutionCache)
			spirit = attr(spiritCache)
			strength = attr(strengthCache)
			anima = attr(animaCache)
			harmony = attr(harmonyCache)
			level = attr(levelCache)
		}
	}
	/** The player name */
	String name

	/** The attack rate. */
	Attribute speed
    /** The spellpower. */
    Attribute mana
    /** Hitpoints (life) */
    Attribute hp
    /** Affects your ability to enchant items OR craft magical items such as potions or even scrolls */
	Attribute intelligence
	/** Resistance to incoming magical attacks and mana growth */
	Attribute psyche
	/** Affects your ability to craft */
	Attribute artistry
	/** Resistance to incoming physical attacks and hp growth */
	Attribute defense
	/** Chance to dodge incoming attacks */
	Attribute reflex
	/** Chance to block incoming attacks */
	Attribute block
	/** Chance to hit the opponent */
	Attribute dexterity
	/** Chance to cause a critical hit */
	Attribute rage
	/** % increase on critical hits. */
	Attribute fury
	/** Resistance to poison and debuffs that affect damage taken */
	Attribute constitution
	/** Resistance to lifedrain and debuffs affecting your attack stats */
	Attribute spirit
	/** Affects the power of physical attacks */
	Attribute strength
	/** Affects the power of magical attacks */
	Attribute anima
	/** "the opposite of rage" : reduces chance to receive a critical hit from enemy */
	Attribute harmony
	/** The level (general power) of the character */
	Attribute level
}

interface Skills {
	/** The entity system */
	EntitySystem SYSTEM = Meta.ENTITY_SYSTEM.create

	/** The default minimum attribute value */
	double DEFAULT_MINIMUM_ATTRIBUTE_VALUE = 0.0

	/** The default maximum attribute value */
	double DEFAULT_MAXIMUM_ATTRIBUTE_VALUE = 99_999.0

	/** The default probability of activation */
	double DEFAULT_PROBABILITY_OF_ACTIVATION = 1.0

	/** The default probability per turn */
	double DEFAULT_PROBABILITY_PER_TURN = 1.0

	/** The default duration in turn */
	double DEFAULT_DURATION_IN_TURN = 999.0
}