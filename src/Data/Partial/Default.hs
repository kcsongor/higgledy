{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE KindSignatures       #-}
{-# LANGUAGE TypeOperators        #-}
{-# LANGUAGE UndecidableInstances #-}
module Data.Partial.Default
  ( Defaults (..)
  ) where

import Data.Kind (Type)
import Data.Maybe (fromMaybe)
import Data.Partial.Types (Partial (..), GPartial_)
import GHC.Generics

-- | We can be guaranteed to reconstruct a value from a partial structure if we
-- also supply a structure of defaults. Every time we encounter a missing
-- field, we borrow a value from the defaults!
--
-- >>> :set -XDataKinds
-- >>> import Control.Lens
-- >>> import Data.Partial.Position
--
-- If we have an empty partial object, it will be entirely populated by the
-- defaults:
--
-- >>> defaults ("Tom", True) mempty
-- ("Tom",True)
--
-- As we add data to our partial structure, these are prioritised over the
-- defaults:
--
-- >>> defaults ("Tom", True) (mempty & position @1 ?~ "Haskell")
-- ("Haskell",True)
class Defaults (structure :: Type) where
  defaults :: structure -> Partial structure -> structure

class GDefaults (rep :: Type -> Type) where
  gdefaults :: rep p -> GPartial_ rep q -> rep r

instance GDefaults inner
    => GDefaults (M1 index meta inner) where

  gdefaults (M1 x) (M1 y)
    = M1 (gdefaults x y)

instance (GDefaults left, GDefaults right)
    => GDefaults (left :*: right) where
  gdefaults (leftX :*: rightX) (leftY :*: rightY)
    = gdefaults leftX leftY :*: gdefaults rightX rightY

instance GDefaults (K1 index inner) where
  gdefaults (K1 inner) (K1 partial)
    = K1 (fromMaybe inner partial)

instance (Generic structure, GDefaults (Rep structure))
    => Defaults structure where
  defaults x (Partial y)
    = to (gdefaults (from x) y)