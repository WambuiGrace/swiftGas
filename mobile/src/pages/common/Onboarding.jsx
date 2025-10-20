import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/common/Button';
import { ROUTES, STORAGE_KEYS } from '../../constants';

const slides = [
  {
    id: 1,
    emoji: '🚚',
    title: 'Fast Delivery',
    description: 'Get your LPG gas delivered to your doorstep in minutes',
  },
  {
    id: 2,
    emoji: '📍',
    title: 'Track in Real-time',
    description: 'Know exactly where your delivery is at all times',
  },
  {
    id: 3,
    emoji: '💳',
    title: 'Easy Payment',
    description: 'Multiple payment options for your convenience',
  },
];

export const Onboarding = () => {
  const [currentSlide, setCurrentSlide] = useState(0);
  const navigate = useNavigate();

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      // Mark onboarding as complete
      localStorage.setItem(STORAGE_KEYS.ONBOARDING_COMPLETE, 'true');
      navigate(ROUTES.LOGIN);
    }
  };

  const handleSkip = () => {
    localStorage.setItem(STORAGE_KEYS.ONBOARDING_COMPLETE, 'true');
    navigate(ROUTES.LOGIN);
  };

  const slide = slides[currentSlide];
  const isLastSlide = currentSlide === slides.length - 1;

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Skip Button */}
      {!isLastSlide && (
        <div className="p-4 flex justify-end">
          <button
            onClick={handleSkip}
            className="text-gray-600 hover:text-gray-900 font-medium"
          >
            Skip
          </button>
        </div>
      )}

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 pb-20">
        {/* Emoji/Icon */}
        <div className="text-8xl mb-8 animate-bounce-slow">
          {slide.emoji}
        </div>

        {/* Title */}
        <h2 className="text-3xl font-bold text-gray-900 mb-4 text-center">
          {slide.title}
        </h2>

        {/* Description */}
        <p className="text-gray-600 text-center text-lg max-w-sm mb-12">
          {slide.description}
        </p>

        {/* Dots Indicator */}
        <div className="flex gap-2 mb-8">
          {slides.map((_, index) => (
            <div
              key={index}
              className={`h-2 rounded-full transition-all duration-300 
                ${index === currentSlide ? 'w-8 bg-primary' : 'w-2 bg-gray-300'}
              `}
            />
          ))}
        </div>

        {/* Action Button */}
        <Button
          onClick={handleNext}
          fullWidth
          size="lg"
          className="max-w-sm"
        >
          {isLastSlide ? 'Get Started' : 'Next'}
        </Button>
      </div>
    </div>
  );
};
